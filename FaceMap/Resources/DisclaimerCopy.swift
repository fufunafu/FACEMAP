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

    By continuing, you confirm you are a licensed practitioner using this app as a planning aid \
    and that the patient has consented to having their face captured.
    """

    static let analysisFooter = """
    For practitioner planning use only. Not a medical recommendation.
    """
}
