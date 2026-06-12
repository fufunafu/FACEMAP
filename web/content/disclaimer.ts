/**
 * Verbatim from FaceMap/Resources/DisclaimerCopy.swift.
 * Do not edit without changing the iOS source first.
 */

export const disclaimer = {
  firstLaunchTitle: "FaceMap is a planning aid",
  firstLaunchBody: `FaceMap is a tool for licensed medical practitioners. It is not a medical device, does not diagnose any condition, and does not prescribe treatment, dose, or specific injection sites. The flagged regions shown by this app are computational outputs based on geometric measurements, not clinical recommendations.

The practitioner is the sole clinical decision-maker for any aesthetic treatment. Always confirm measurements against direct examination of the patient.

Metric outputs are not clinically meaningful until the landmark indices have been calibrated on this device — open a captured case and tap the scope icon in the Analysis toolbar to calibrate. A warning is shown on every analysis until calibration is complete.

By continuing, you confirm you are a licensed practitioner using this app as a planning aid and that the patient has consented to having their face captured.`,
  analysisFooter: "For practitioner planning use only. Not a medical recommendation.",
} as const;
