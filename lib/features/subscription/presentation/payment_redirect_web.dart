import 'dart:html' as html;

void redirectToExternalPayment(String paymentLink) {
  html.window.location.assign(paymentLink);
}
