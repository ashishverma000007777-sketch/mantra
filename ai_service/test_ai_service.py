# ai_service/test_ai_service.py
"""
Mantra AI Service Algorithm & Moderation Unit Tests
Tests fast regex scanning, Hinglish detection, compatibility scoring,
and multi-signal fake profile detection algorithms.
"""

import unittest
import re
import math

# Extract and test algorithms matching main.py
BAD_PATTERNS = [
    r'\b(nude|nudes|naked|sex|fuck|pussy|dick|cock|boobs|tits)\b',
    r'\b(send\s+pic|send\s+photo|watsapp|whatsapp\s+me|insta\s+me)\b',
    r'\b(come\s+home|meet\s+me\s+alone|hotel|room)\b',
    r'([\+\d\-\(\)\s]{10,})',  # Phone number pattern
    r'@[a-zA-Z0-9._]+',  # Instagram handle
]

HINGLISH_BAD = [
    'bhosdike', 'madarchod', 'bhenchod', 'chutiya', 'randi',
    'gaand', 'lund', 'chut', 'harami', 'saala',
]

def fast_regex_scan(text: str) -> tuple[bool, list]:
    text_lower = text.lower()
    categories = []
    for pattern in BAD_PATTERNS:
        if re.search(pattern, text_lower):
            categories.append('explicit_or_pii')
    for word in HINGLISH_BAD:
        if word in text_lower:
            categories.append('hinglish_slur')
    return len(categories) > 0, categories

def compute_compatibility_score(user_a_tags, user_b_tags, user_a_city, user_b_city, user_a_intent=None, user_b_intent=None):
    set_a = set(user_a_tags)
    set_b = set(user_b_tags)
    if set_a or set_b:
        jaccard = len(set_a & set_b) / len(set_a | set_b)
    else:
        jaccard = 0.0

    city_bonus = 0.1 if user_a_city.lower() == user_b_city.lower() else 0.0

    intent_bonus = 0.0
    if user_a_intent and user_b_intent:
        if user_a_intent == user_b_intent:
            intent_bonus = 0.05
        elif {user_a_intent, user_b_intent} == {'meaningful', 'partner'}:
            intent_bonus = 0.04

    total = (jaccard * 0.55) + city_bonus + intent_bonus
    score = min(int(total * 100) + 25, 99)
    return score, jaccard

def compute_fake_score(account_age_days: int, message_count: int, report_count: int, profile_text: str, photo_urls: list):
    score = 0.0
    signals = []

    if account_age_days < 1 and message_count > 20:
        score += 0.35
        signals.append('spam_behavior_new_account')

    if report_count >= 3:
        score += 0.30
        signals.append('multiple_reports')

    if report_count >= 5:
        score += 0.20
        signals.append('high_report_count')

    text_lower = profile_text.lower()
    if any(kw in text_lower for kw in ['whatsapp me', 'instagram me', 'telegram', 'snapchat']):
        score += 0.25
        signals.append('off_platform_redirect')

    if len(profile_text) < 20 and len(photo_urls) == 0:
        score += 0.15
        signals.append('empty_profile')

    score = min(score, 1.0)
    decision = 'ban' if score >= 0.80 else 'restrict' if score >= 0.55 else 'monitor' if score >= 0.30 else 'ok'
    return round(score, 3), decision, signals


class TestMantraAIService(unittest.TestCase):

    def test_clean_message_passes_regex_scan(self):
        flagged, categories = fast_regex_scan("I really enjoy reading Hindi poetry and drinking chai on Sunday mornings.")
        self.assertFalse(flagged)
        self.assertEqual(len(categories), 0)

    def test_explicit_message_detected(self):
        flagged, categories = fast_regex_scan("Hey send nudes please")
        self.assertTrue(flagged)
        self.assertIn('explicit_or_pii', categories)

    def test_hinglish_slur_detected(self):
        flagged, categories = fast_regex_scan("Tu ek number ka chutiya hai")
        self.assertTrue(flagged)
        self.assertIn('hinglish_slur', categories)

    def test_phone_number_pii_detected(self):
        flagged, categories = fast_regex_scan("Call me on +91 98765 43210 tonight")
        self.assertTrue(flagged)
        self.assertIn('explicit_or_pii', categories)

    def test_instagram_handle_detected(self):
        flagged, categories = fast_regex_scan("Ping me at @priya_wanderlust")
        self.assertTrue(flagged)
        self.assertIn('explicit_or_pii', categories)

    def test_compatibility_scoring_high_overlap(self):
        tags_a = ['reading', 'chai', 'bollywood', 'hiking']
        tags_b = ['reading', 'chai', 'indie_music']
        score, jaccard = compute_compatibility_score(tags_a, tags_b, 'Mumbai', 'Mumbai', 'long_term', 'long_term')
        self.assertGreater(score, 50)
        self.assertGreater(jaccard, 0.3)

    def test_compatibility_scoring_city_bonus(self):
        score_same_city, _ = compute_compatibility_score(['books'], ['books'], 'Delhi', 'Delhi')
        score_diff_city, _ = compute_compatibility_score(['books'], ['books'], 'Delhi', 'Bengaluru')
        self.assertGreater(score_same_city, score_diff_city)

    def test_fake_profile_legitimate_user(self):
        score, decision, signals = compute_fake_score(
            account_age_days=15,
            message_count=5,
            report_count=0,
            profile_text="Architect based in Pune, love vintage cinema and filter coffee.",
            photo_urls=["https://storage/p1.jpg"]
        )
        self.assertEqual(decision, 'ok')
        self.assertLess(score, 0.30)
        self.assertEqual(len(signals), 0)

    def test_fake_profile_spam_bot_banned(self):
        score, decision, signals = compute_fake_score(
            account_age_days=0,
            message_count=45,
            report_count=4,
            profile_text="WhatsApp me for fun",
            photo_urls=[]
        )
        self.assertIn(decision, ['restrict', 'ban'])
        self.assertGreaterEqual(score, 0.70)
        self.assertIn('spam_behavior_new_account', signals)
        self.assertIn('off_platform_redirect', signals)


if __name__ == '__main__':
    unittest.main()
