module ActivityLogMain

  CallConnected = 'Connected'
  NextStepComplete = 'Complete'
  NextStepCallBack = 'Call Back'
  CallToStaff = 'To Staff'
  CallToPlayer = 'To Player'
  CallBadNumber = 'Bad Number'
  RankBadContact = '-1 - bad contact'
  StudyProtocol = 'Study'
  ActivitySubProcess = 'Activity'
  PhoneLogProtocolEvent = 'Phone Log'

  include FeatureHelper
  include FeatureSupport
  include MasterDataSupport
  include ModelSupport
  include PhoneLogSupport

  include ActivityLogSetup
  include PhoneSetup
  include PlayerSetup
  include SpecSetup

  include LogCallActions
  include LogExpectations
  include PhoneListActions
  include PhoneLogActions
  include PlayerContactActions

end
