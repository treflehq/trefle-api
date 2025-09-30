class SubmitCorrection
  include Interactor::Organizer

  organize Corrections::ValidateRecordCorrection,
           Corrections::SaveRecordCorrection
end
