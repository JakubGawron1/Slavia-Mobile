import 'package:flutter/material.dart';

import '../models/payment.dart';

enum AthletePaymentKpiTone { success, error, warning, info }

class AthletePaymentKpi {
  final String value;
  final String hint;
  final AthletePaymentKpiTone tone;

  const AthletePaymentKpi({
    required this.value,
    required this.hint,
    required this.tone,
  });
}

AthletePaymentKpi athletePaymentKpiFromStatus(PaymentStatusResponse ps) {
  if (ps.isPaid) {
    return AthletePaymentKpi(
      value: 'Opłacona',
      hint: ps.month,
      tone: AthletePaymentKpiTone.success,
    );
  }
  if (ps.isOverdue) {
    return AthletePaymentKpi(
      value: 'Nieopłacona',
      hint: ps.month,
      tone: AthletePaymentKpiTone.error,
    );
  }
  if (ps.hasStandingOrder) {
    return AthletePaymentKpi(
      value: 'Przelew stały',
      hint: 'Auto-składka · ${ps.month}',
      tone: AthletePaymentKpiTone.info,
    );
  }
  return AthletePaymentKpi(
    value: 'Oczekuje',
    hint: ps.month,
    tone: AthletePaymentKpiTone.warning,
  );
}

Color athletePaymentKpiColor(
  AthletePaymentKpiTone tone,
  ColorScheme cs,
  Color primary,
) {
  return switch (tone) {
    AthletePaymentKpiTone.success => Colors.green.shade700,
    AthletePaymentKpiTone.error => cs.error,
    AthletePaymentKpiTone.warning => Colors.amber.shade800,
    AthletePaymentKpiTone.info => primary,
  };
}
