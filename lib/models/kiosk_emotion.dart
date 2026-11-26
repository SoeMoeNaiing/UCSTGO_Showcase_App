import 'package:flutter/material.dart';

enum KioskEmotion {
  mindBlown(
    keyName: 'mind_blown',
    label: 'MIND BLOWN',
    assetUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f92f/512.webp',
    accent: Color(0xFFFF2E93),
    scoreWeight: 5,
  ),
  lovedIt(
    keyName: 'loved_it',
    label: 'LOVED IT',
    assetUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f60d/512.webp',
    accent: Color(0xFFA3FF12),
    scoreWeight: 5,
  ),
  impressed(
    keyName: 'impressed',
    label: 'IMPRESSED',
    assetUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f929/512.webp',
    accent: Color(0xFF00E5FF),
    scoreWeight: 4,
  ),
  inspired(
    keyName: 'inspired',
    label: 'INSPIRED',
    assetUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.webp',
    accent: Color(0xFFFFD60A),
    scoreWeight: 4,
  ),
  curious(
    keyName: 'curious',
    label: 'CURIOUS',
    assetUrl: 'https://fonts.gstatic.com/s/e/notoemoji/latest/1f914/512.webp',
    accent: Color(0xFF9D4EDD),
    scoreWeight: 3,
  );

  const KioskEmotion({
    required this.keyName,
    required this.label,
    required this.assetUrl,
    required this.accent,
    required this.scoreWeight,
  });

  final String keyName;
  final String label;
  final String assetUrl;
  final Color accent;
  final int scoreWeight;
}

const List<String> kQuickFeedbackTags = [
  'GREAT UI',
  'REAL-WORLD IMPACT',
  'SMOOTH DEMO',
  'CREATIVE IDEA',
];
