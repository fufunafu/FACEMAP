import Foundation

enum DisclaimerCopy {
    static let firstLaunchTitle = "FaceMap is a planning aid"

    static let firstLaunchBody = """
    FaceMap is a tool for licensed medical practitioners. It is not a medical device, \
    does not diagnose any condition, and does not prescribe treatment, dose, \
    or specific injection sites. The flagged regions shown by this app are computational \
    outputs based on geometric measurements, not clinical recommendations.

    The practitioner is the sole clinical decision-maker for any aesthetic treatment. \
    Always confirm measurements against direct examination of the patient.

    Metric outputs are not clinically meaningful until the landmark indices have been \
    calibrated on this device — open a captured case and tap the scope icon in the \
    Analysis toolbar to calibrate. A warning is shown on every analysis until \
    calibration is complete.

    By continuing, you confirm you are a licensed practitioner using this app as a planning aid \
    and that the patient has consented to having their face captured.
    """

    static let analysisFooter = """
    For practitioner planning use only. Not a medical recommendation.
    """

    static let uncalibratedWarning = """
    Landmarks not calibrated on this device — values are not anatomically meaningful until calibrated. Tap to calibrate.
    """

    static let pdfUncalibratedWarning = """
    Generated with uncalibrated landmark indices — measurements are not clinically validated.
    """

    /// Placeholder bio copy. Dr Nikolis to supply final text + portrait.
    // PLACEHOLDER — pending Dr Nikolis review
    static let aboutNikolis = """
    Dr Andreas Nikolis is an aesthetic medicine specialist whose published \
    Facial Assessment Scale (FAS) grades five facets of the face — Skin quality, \
    Facial shape, Proportions, Symmetry, and Expression — each scored 0–3 and \
    plotted on a circular chart that grows outward with severity. That five-facet \
    assessment informs the analysis used throughout FaceMap.

    This app is a planning aid for licensed practitioners and does not replace \
    direct clinical examination. The framework, terminology, and visual language \
    used here are derived from his work; clinical decisions remain with the \
    treating practitioner.
    """

    static let pdfFooter = """
    FaceMap planning aid · Not a medical device · Practitioner is the sole clinical decision-maker.
    """
}
