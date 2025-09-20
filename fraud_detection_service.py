#!/usr/bin/env python3
"""
SurakshaPay Fraud Detection Microservice
This service analyzes transactions and voice commands for fraudulent patterns.
"""

from flask import Flask, request, jsonify
import re
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Fraud detection patterns
GAMBLING_KEYWORDS = [
    # English
    'bet', 'gambling', 'casino', 'poker', 'lottery', 'jackpot', 'wager', 'stake',
    'betting', 'gamble', 'slot', 'roulette', 'blackjack', 'baccarat', 'craps',
    'sportsbook', 'bookmaker', 'odds', 'handicap', 'spread', 'parlay',
    
    # Hindi
    'शर्त', 'जुआ', 'कैसीनो', 'लॉटरी', 'जैकपॉट', 'सट्टा', 'बाजी', 'पैसा',
    'रुपया', 'टिकट', 'नंबर', 'गेम', 'खेल', 'जीत', 'हार', 'पैसा',
    
    # Bengali
    'বাজি', 'জুয়া', 'ক্যাসিনো', 'লটারি', 'জ্যাকপট', 'টিকিট', 'নম্বর',
    'গেম', 'খেলা', 'জয়', 'হার', 'টাকা',
    
    # Tamil
    'பந்தயம்', 'சூதாட்டம்', 'லாட்டரி', 'ஜாக்பாட்', 'டிக்கெட்', 'எண்',
    'விளையாட்டு', 'விளையாடு', 'வெற்றி', 'தோல்வி', 'பணம்',
    
    # Telugu
    'జూదం', 'లాటరీ', 'కాసినో', 'జాక్పాట్', 'టికెట్', 'సంఖ్య',
    'గేమ్', 'ఆడు', 'గెలుపు', 'ఓటమి', 'డబ్బు'
]

SUSPICIOUS_PATTERNS = [
    r'\b\d{4,6}\b',  # 4-6 digit numbers (could be PINs)
    r'\b\d{10,}\b',  # Long number sequences
    r'urgent|emergency|quick|fast|immediate',  # Urgency keywords
    r'secret|confidential|private',  # Secrecy keywords
    r'call me|contact me|message me',  # Contact requests
]

# Transaction limits and patterns
MAX_DAILY_TRANSACTIONS = 10
MAX_HOURLY_TRANSACTIONS = 5
MAX_SINGLE_TRANSACTION = 50000
SUSPICIOUS_AMOUNT_THRESHOLD = 10000

class FraudDetectionService:
    def __init__(self):
        self.transaction_history = {}
        self.voice_command_history = {}
    
    def detect_fraud(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Main fraud detection method
        """
        fraud_indicators = []
        risk_score = 0
        
        # Check gambling keywords
        if self._check_gambling_keywords(data):
            fraud_indicators.append("gambling_keywords_detected")
            risk_score += 30
        
        # Check transaction patterns
        if self._check_transaction_patterns(data):
            fraud_indicators.append("suspicious_transaction_pattern")
            risk_score += 25
        
        # Check amount patterns
        if self._check_amount_patterns(data):
            fraud_indicators.append("suspicious_amount_pattern")
            risk_score += 20
        
        # Check voice command patterns
        if self._check_voice_patterns(data):
            fraud_indicators.append("suspicious_voice_pattern")
            risk_score += 15
        
        # Check time-based patterns
        if self._check_time_patterns(data):
            fraud_indicators.append("suspicious_time_pattern")
            risk_score += 10
        
        is_fraud = risk_score >= 50 or len(fraud_indicators) >= 2
        
        return {
            "is_fraud": is_fraud,
            "risk_score": min(risk_score, 100),
            "fraud_indicators": fraud_indicators,
            "confidence": min(risk_score / 100, 1.0),
            "timestamp": datetime.now().isoformat()
        }
    
    def _check_gambling_keywords(self, data: Dict[str, Any]) -> bool:
        """Check for gambling-related keywords in description or voice commands"""
        text_to_check = ""
        
        if 'description' in data and data['description']:
            text_to_check += data['description'].lower() + " "
        
        if 'voice_command' in data and data['voice_command']:
            text_to_check += data['voice_command'].lower() + " "
        
        if 'recipient_name' in data and data['recipient_name']:
            text_to_check += data['recipient_name'].lower() + " "
        
        for keyword in GAMBLING_KEYWORDS:
            if keyword.lower() in text_to_check:
                logger.warning(f"Gambling keyword detected: {keyword}")
                return True
        
        return False
    
    def _check_transaction_patterns(self, data: Dict[str, Any]) -> bool:
        """Check for suspicious transaction patterns"""
        user_id = data.get('user_id')
        if not user_id:
            return False
        
        # Get user's transaction history
        user_transactions = self.transaction_history.get(user_id, [])
        
        # Check for rapid successive transactions
        now = datetime.now()
        recent_transactions = [
            tx for tx in user_transactions
            if now - datetime.fromisoformat(tx['timestamp']) < timedelta(hours=1)
        ]
        
        if len(recent_transactions) > MAX_HOURLY_TRANSACTIONS:
            logger.warning(f"Too many transactions in 1 hour: {len(recent_transactions)}")
            return True
        
        # Check daily transaction count
        daily_transactions = [
            tx for tx in user_transactions
            if now - datetime.fromisoformat(tx['timestamp']) < timedelta(days=1)
        ]
        
        if len(daily_transactions) > MAX_DAILY_TRANSACTIONS:
            logger.warning(f"Too many transactions in 1 day: {len(daily_transactions)}")
            return True
        
        return False
    
    def _check_amount_patterns(self, data: Dict[str, Any]) -> bool:
        """Check for suspicious amount patterns"""
        amount = data.get('amount', 0)
        
        # Check for very large amounts
        if amount > MAX_SINGLE_TRANSACTION:
            logger.warning(f"Transaction amount exceeds limit: {amount}")
            return True
        
        # Check for suspicious amount patterns (e.g., round numbers, repeated digits)
        amount_str = str(int(amount))
        if len(set(amount_str)) == 1:  # All same digits (e.g., 1111, 9999)
            logger.warning(f"Suspicious amount pattern: {amount}")
            return True
        
        # Check for amounts just under common limits
        if amount > SUSPICIOUS_AMOUNT_THRESHOLD and amount % 1000 == 0:
            logger.warning(f"Large round amount: {amount}")
            return True
        
        return False
    
    def _check_voice_patterns(self, data: Dict[str, Any]) -> bool:
        """Check for suspicious voice command patterns"""
        voice_command = data.get('voice_command', '')
        if not voice_command:
            return False
        
        voice_lower = voice_command.lower()
        
        # Check for suspicious patterns
        for pattern in SUSPICIOUS_PATTERNS:
            if re.search(pattern, voice_lower):
                logger.warning(f"Suspicious voice pattern detected: {pattern}")
                return True
        
        # Check for repeated commands
        user_id = data.get('user_id')
        if user_id:
            user_commands = self.voice_command_history.get(user_id, [])
            recent_commands = [
                cmd for cmd in user_commands
                if datetime.now() - datetime.fromisoformat(cmd['timestamp']) < timedelta(minutes=5)
            ]
            
            if len(recent_commands) > 3:
                logger.warning(f"Too many voice commands in 5 minutes: {len(recent_commands)}")
                return True
        
        return False
    
    def _check_time_patterns(self, data: Dict[str, Any]) -> bool:
        """Check for suspicious time-based patterns"""
        now = datetime.now()
        hour = now.hour
        
        # Check for transactions at unusual hours (2 AM - 5 AM)
        if 2 <= hour <= 5:
            logger.warning(f"Transaction at unusual hour: {hour}")
            return True
        
        return False
    
    def log_transaction(self, user_id: str, transaction_data: Dict[str, Any]):
        """Log a transaction for pattern analysis"""
        if user_id not in self.transaction_history:
            self.transaction_history[user_id] = []
        
        transaction_data['timestamp'] = datetime.now().isoformat()
        self.transaction_history[user_id].append(transaction_data)
        
        # Keep only last 100 transactions per user
        if len(self.transaction_history[user_id]) > 100:
            self.transaction_history[user_id] = self.transaction_history[user_id][-100:]
    
    def log_voice_command(self, user_id: str, command: str):
        """Log a voice command for pattern analysis"""
        if user_id not in self.voice_command_history:
            self.voice_command_history[user_id] = []
        
        self.voice_command_history[user_id].append({
            'command': command,
            'timestamp': datetime.now().isoformat()
        })
        
        # Keep only last 50 commands per user
        if len(self.voice_command_history[user_id]) > 50:
            self.voice_command_history[user_id] = self.voice_command_history[user_id][-50:]

# Initialize fraud detection service
fraud_service = FraudDetectionService()

@app.route('/detect-fraud', methods=['POST'])
def detect_fraud():
    """Main fraud detection endpoint"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Log the transaction/command for future analysis
        user_id = data.get('user_id')
        if user_id:
            fraud_service.log_transaction(user_id, data)
            
            if 'voice_command' in data:
                fraud_service.log_voice_command(user_id, data['voice_command'])
        
        # Perform fraud detection
        result = fraud_service.detect_fraud(data)
        
        logger.info(f"Fraud detection result: {result}")
        
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"Error in fraud detection: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/process-voice', methods=['POST'])
def process_voice():
    """Process voice commands and extract intent"""
    try:
        data = request.get_json()
        
        if not data or 'command' not in data:
            return jsonify({'error': 'No command provided'}), 400
        
        command = data['command'].lower()
        user_id = data.get('user_id', '')
        
        # Log the voice command
        if user_id:
            fraud_service.log_voice_command(user_id, command)
        
        # Extract intent and parameters
        result = extract_voice_intent(command)
        
        return jsonify(result)
    
    except Exception as e:
        logger.error(f"Error processing voice command: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500

def extract_voice_intent(command: str) -> Dict[str, Any]:
    """Extract intent and parameters from voice command"""
    
    # Send money patterns
    send_patterns = [
        r'send\s+(\d+)\s+to\s+([a-zA-Z\s]+)',
        r'(\d+)\s+rupees?\s+to\s+([a-zA-Z\s]+)',
        r'([a-zA-Z\s]+)\s+ko\s+(\d+)\s+bhej',
        r'([a-zA-Z\s]+)\s+को\s+(\d+)\s+भेज',
    ]
    
    for pattern in send_patterns:
        match = re.search(pattern, command)
        if match:
            if 'ko' in pattern or 'को' in pattern:
                # Hindi pattern: name ko amount bhej
                return {
                    'intent': 'send_money',
                    'recipient': match.group(1).strip(),
                    'amount': float(match.group(2)),
                    'confidence': 0.9
                }
            else:
                # English pattern: send amount to name
                return {
                    'intent': 'send_money',
                    'amount': float(match.group(1)),
                    'recipient': match.group(2).strip(),
                    'confidence': 0.9
                }
    
    # Receive money patterns
    receive_patterns = [
        r'receive\s+money',
        r'show\s+qr',
        r'qr\s+code',
        r'पैसा\s+ले',
        r'क्यूआर\s+दिखा',
    ]
    
    for pattern in receive_patterns:
        if re.search(pattern, command):
            return {
                'intent': 'receive_money',
                'confidence': 0.8
            }
    
    # Balance check patterns
    balance_patterns = [
        r'balance',
        r'how\s+much',
        r'कितना\s+पैसा',
        r'बैलेंस',
        r'बाकी',
    ]
    
    for pattern in balance_patterns:
        if re.search(pattern, command):
            return {
                'intent': 'check_balance',
                'confidence': 0.8
            }
    
    # History patterns
    history_patterns = [
        r'history',
        r'transactions',
        r'list',
        r'इतिहास',
        r'लिस्ट',
    ]
    
    for pattern in history_patterns:
        if re.search(pattern, command):
            return {
                'intent': 'view_history',
                'confidence': 0.8
            }
    
    # Help patterns
    help_patterns = [
        r'help',
        r'what\s+can\s+you\s+do',
        r'मदद',
        r'क्या\s+कर\s+सकते\s+हो',
    ]
    
    for pattern in help_patterns:
        if re.search(pattern, command):
            return {
                'intent': 'help',
                'confidence': 0.8
            }
    
    # Default: unknown intent
    return {
        'intent': 'unknown',
        'confidence': 0.1,
        'original_command': command
    }

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'fraud-detection'
    })

if __name__ == '__main__':
    logger.info("Starting SurakshaPay Fraud Detection Service...")
    app.run(host='0.0.0.0', port=8000, debug=True)

