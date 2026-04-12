import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get(String key) =>
      _localizedStrings[locale.languageCode]?[key] ??
      _localizedStrings['en']![key] ??
      key;

  String get appName => get('app_name');
  String get profileTitle => get('profile_title');
  String get language => get('language');
  String get saveMedicalProfile => get('save_medical_profile');
  String get criticalMedicalInfo => get('critical_medical_info');
  String get emergencyContacts => get('emergency_contacts');
  String get goldenHourDetails => get('golden_hour_details');
  String get sosLock => get('sos_lock');
  String get topLifeSavers => get('top_life_savers');
  String get livesSaved => get('lives_saved');
  String get activeAlerts => get('active_alerts');
  String get rank => get('rank');
  String get onDuty => get('on_duty');
  String get standby => get('standby');
  String get sosButton => get('sos');
  String get callNow => get('call_now');
  String get quickGuide => get('quick_guide');
  String get detailedInstructions => get('detailed_instructions');
  String get redFlags => get('red_flags');
  String get cautions => get('cautions');
  String get voiceWalkthrough => get('voice_walkthrough');
  String get playing => get('playing');
  String get swipeNextGuide => get('swipe_next_guide');
  String get watchVideoGuide => get('watch_video_guide');
  String get emergencyGridScan => get('emergency_grid_scan');
  String get areaTelemetry => get('area_telemetry');
  String get reportHazard => get('report_hazard');
  String get todaysDuty => get('todays_duty');
  String get bloodType => get('blood_type');
  String get allergies => get('allergies');
  String get medicalConditions => get('medical_conditions');
  String get contactName => get('contact_name');
  String get contactPhone => get('contact_phone');
  String get contactEmail => get('contact_email');
  String get relationship => get('relationship');
  String get medications => get('medications');
  String get organDonor => get('organ_donor');
  String get goodMorning => get('good_morning');
  String get goodAfternoon => get('good_afternoon');
  String get goodEvening => get('good_evening');
  String get hospitals => get('hospitals');
  String get visualWalkthrough => get('visual_walkthrough');
  String get lifeline => get('lifeline');
  String get navHome => get('nav_home');
  String get navMap => get('nav_map');
  String get navGrid => get('nav_grid');
  String get navProfile => get('nav_profile');
  String mapCachingOfflinePct(int pct) =>
      get('map_caching_offline_pct').replaceAll('{pct}', '$pct');
  String get mapDrillPracticeBanner => get('map_drill_practice_banner');
  String get mapRecenterTooltip => get('map_recenter_tooltip');
  String get mapLegendHospital => get('map_legend_hospital');
  String get mapLegendLiveSosHistory => get('map_legend_live_sos_history');
  String get mapLegendPastThisHex => get('map_legend_past_this_hex');
  String mapLegendIncidentsInArea(int n) =>
      get('map_legend_in_area').replaceAll('{n}', '$n');
  String mapLegendIncidentsInCell(int n) =>
      get('map_legend_in_cell').replaceAll('{n}', '$n');
  String get mapLegendVolunteersOnDuty => get('map_legend_volunteers_on_duty');
  String mapLegendVolunteersInGrid(int n) =>
      get('map_legend_volunteers_in_grid').replaceAll('{n}', '$n');
  String get mapLegendResponderScene => get('map_legend_responder_scene');
  String mapResponderRoutes(int n) => (n == 1
          ? get('map_responder_routes_one')
          : get('map_responder_routes_many'))
      .replaceAll('{n}', '$n');
  String get mapFiltersTitle => get('map_filters_title');
  String get volunteerActiveBrowserLocationOff =>
      get('volunteer_active_browser_location_off');
  String get volunteerActiveLocationRequired =>
      get('volunteer_active_location_required');
  String volunteerActiveMapLoadFailed(String detail) =>
      get('volunteer_active_map_load_failed').replaceAll('{detail}', detail);
  String get volunteerActiveNoMapCoords => get('volunteer_active_no_map_coords');
  String get volunteerActiveGpsUnavailable =>
      get('volunteer_active_gps_unavailable');
  String get volunteerActiveOfflineQrTitle =>
      get('volunteer_active_offline_qr_title');
  String get volunteerActiveOfflineQrBody =>
      get('volunteer_active_offline_qr_body');
  String get volunteerActiveClose => get('volunteer_active_close');
  String get volunteerActiveDispatchedServices =>
      get('volunteer_active_dispatched_services');
  String get volunteerActiveAmbulance => get('volunteer_active_ambulance');
  String get volunteerActiveOnScene => get('volunteer_active_on_scene');
  String get volunteerActiveEnRoute => get('volunteer_active_en_route');
  String get volunteerActiveExitTitle => get('volunteer_active_exit_title');
  String get volunteerActiveLeaveVictim => get('volunteer_active_leave_victim');
  String get volunteerActiveLeaveVolunteer =>
      get('volunteer_active_leave_volunteer');
  String get volunteerActiveStay => get('volunteer_active_stay');
  String get volunteerActiveExit => get('volunteer_active_exit');
  String get volunteerActiveSosExpired => get('volunteer_active_sos_expired');
  String get volunteerActiveBackToResponse =>
      get('volunteer_active_back_to_response');
  String get volunteerActiveOfflineQrAccess =>
      get('volunteer_active_offline_qr_access');
  String get volunteerActiveHospitalEvLabel =>
      get('volunteer_active_hospital_ev_label');
  String get volunteerActiveHospitalEvSubtitle =>
      get('volunteer_active_hospital_ev_subtitle');
  String get volunteerActiveNearbyHospitalsMaps =>
      get('volunteer_active_nearby_hospitals_maps');
  String get volunteerActiveChecklistSaved =>
      get('volunteer_active_checklist_saved');
  String volunteerActiveSaveFailed(String detail) =>
      get('volunteer_active_save_failed').replaceAll('{detail}', detail);
  String get volunteerActivePhotoLimit => get('volunteer_active_photo_limit');
  String volunteerActivePhotoError(String detail) =>
      get('volunteer_active_photo_error').replaceAll('{detail}', detail);
  String get volunteerActiveVictimLoading =>
      get('volunteer_active_victim_loading');
  String get sosActiveUpdateSentLivekit => get('sos_active_update_sent_livekit');
  String get sosActiveUpdateSentChannel => get('sos_active_update_sent_channel');
  String get sosActiveCouldNotSendUpdate =>
      get('sos_active_could_not_send_update');
  String get sosActiveVoiceTextSent => get('sos_active_voice_text_sent');
  String get sosActiveCouldNotSendVoice => get('sos_active_could_not_send_voice');
  String get sosActiveVoiceUpdateSent => get('sos_active_voice_update_sent');
  String get sosActiveVoiceRecordFailed => get('sos_active_voice_record_failed');
  String get sosActiveRoutesToYou => get('sos_active_routes_to_you');
  String get sosActiveAvgResponseTime => get('sos_active_avg_response_time');
  String get sosActiveRecentVolume => get('sos_active_recent_volume');
  String get sosActiveCongestionWarning => get('sos_active_congestion_warning');
  String get stepPrefix => get('step_prefix');
  String get highlightsSteps => get('highlights_steps');
  String get offlineMode => get('offline_mode');
  String get volunteer => get('volunteer');
  String get unranked => get('unranked');
  String get live => get('live');
  String get you => get('you');
  String get saved => get('saved');
  String get xpResponses => get('xp_responses');
  String get dutyMonitoring => get('duty_monitoring');
  String get turnOnDutyMsg => get('turn_on_duty_msg');
  String get onDutySnack => get('on_duty_snack');
  String get offDutySnack => get('off_duty_snack');
  String get nearbyVolunteersLocating => get('nearby_volunteers_locating');
  String get activeVolunteersGridNone => get('active_volunteers_grid_none');
  String activeVolunteersGridCount(int n) {
    if (n <= 0) return activeVolunteersGridNone;
    return get('active_volunteers_grid').replaceAll('{n}', '$n');
  }

  String get leaderboardOffline => get('leaderboard_offline');
  String get leaderboardOfflineSub => get('leaderboard_offline_sub');
  String get leaderboardEmptyPrimary => get('leaderboard_empty_primary');
  String get leaderboardEmptySecondary => get('leaderboard_empty_secondary');
  String get leaderboardOnDutyFallbackTitle => get('leaderboard_on_duty_fallback_title');
  String get leaderboardOnDutyStat => get('leaderboard_on_duty_stat');
  String get leaderboardViewGrid => get('leaderboard_view_grid');
  String get leaderboardSoloOnDuty => get('leaderboard_solo_on_duty');
  String get setSosPinFirst => get('set_sos_pin_first');
  String get setPinSafetyMsg => get('set_pin_safety_msg');
  String get setPinNow => get('set_pin_now');
  String get later => get('later');

  // Emergency consent
  String get emergencyConsentTitle => get('emergency_consent_title');
  String get emergencyConsentBody => get('emergency_consent_body');
  String get consentNotNow => get('consent_not_now');
  String get consentContinue => get('consent_continue');

  // SOS screen
  String get sosScreenTitle => get('sos_screen_title');
  String get sosHoldBanner => get('sos_hold_banner');
  String get sosHoldButton => get('sos_hold_button');
  String get sosOfflineQueued => get('sos_offline_queued');
  String get sosSemanticsHoldHint => get('sos_semantics_hold_hint');
  String get sosStarting => get('sos_starting');
  String get sosReleaseToSend => get('sos_release_to_send');
  String get sosReleaseCancel => get('sos_release_cancel');
  String get sosCheckConnectionRetry => get('sos_check_connection_retry');
  String get sosRetry => get('sos_retry');
  String get sosActiveFlowFailed => get('sos_active_flow_failed');
  String get sosPinDispatchBody => get('sos_pin_dispatch_body');
  String sosFailedMessage(String detail) =>
      get('sos_failed_prefix').replaceAll('{detail}', detail);

  // Volunteer voice mode prompt
  String get volunteerVoiceModeTitle => get('volunteer_voice_mode_title');
  String get volunteerVoiceModeSubtitle => get('volunteer_voice_mode_subtitle');
  String get volunteerVoiceModeAudioTitle =>
      get('volunteer_voice_mode_audio_title');
  String get volunteerVoiceModeAudioSubtitle =>
      get('volunteer_voice_mode_audio_subtitle');
  String get volunteerVoiceModeSilentTitle =>
      get('volunteer_voice_mode_silent_title');
  String get volunteerVoiceModeSilentSubtitle =>
      get('volunteer_voice_mode_silent_subtitle');
  String get volunteerVoiceModeFooter =>
      get('volunteer_voice_mode_footer');

  // Common actions
  String get cancel => get('cancel');
  String get save => get('save');

  // PIN dialog
  String get pinChangeTitle => get('pin_change_title');
  String get pinSetTitle => get('pin_set_title');
  String get pinHintNew => get('pin_hint_new');
  String get pinHintConfirm => get('pin_hint_confirm');
  String get pinErrorTooShort => get('pin_error_too_short');
  String get pinErrorMismatch => get('pin_error_mismatch');

  // Profile sync & messages
  String get profileSynced => get('profile_synced');
  String get profileNotSynced => get('profile_not_synced');
  String get profileSaving => get('profile_saving');
  String get profileQueuedOffline => get('profile_queued_offline');
  String get profileSaveFailed => get('profile_save_failed');
  String get profileSaveTimedOut => get('profile_save_timed_out');
  String get profileTimeJustNow => get('profile_time_just_now');
  String profileTimeMinAgo(int n) =>
      get('profile_time_min_ago').replaceAll('{n}', '$n');
  String profileTimeHoursAgo(int n) =>
      get('profile_time_hours_ago').replaceAll('{n}', '$n');
  String profileTimeDaysAgo(int n) =>
      get('profile_time_days_ago').replaceAll('{n}', '$n');
  String get profileDbUnreachable => get('profile_db_unreachable');
  String get profileSavedOfflineMsg => get('profile_saved_offline_msg');
  String get profileSavedMsg => get('profile_saved_msg');
  String get profileSaveTimeoutMsg => get('profile_save_timeout_msg');
  String profileSaveError(String e) =>
      get('profile_save_error').replaceAll('{e}', e);
  String get profilePinSavedOffline => get('profile_pin_saved_offline');
  String get profilePinSaved => get('profile_pin_saved');
  String profilePinSaveError(String e) =>
      get('profile_pin_save_error').replaceAll('{e}', e);

  String get drillProfileBanner => get('drill_profile_banner');
  String get profileSmsContactTitle => get('profile_sms_contact_title');
  String get profileSmsContactSubtitle => get('profile_sms_contact_subtitle');
  String get profileDispatchDeskTitle => get('profile_dispatch_desk_title');
  String get profileDispatchDeskSubtitle => get('profile_dispatch_desk_subtitle');
  String get profilePinStatusSet => get('profile_pin_status_set');
  String get profilePinStatusUnset => get('profile_pin_status_unset');
  String get profileChangePinBtn => get('profile_change_pin_btn');
  String get profileSetPinBtn => get('profile_set_pin_btn');
  String get profilePinExitNote => get('profile_pin_exit_note');
  String get profileSosPinTitle => get('profile_sos_pin_title');
  String get profileVoiceAgentEnableTitle => get('profile_voice_agent_enable_title');
  String get profileVoiceAgentEnableSubtitle => get('profile_voice_agent_enable_subtitle');
  String get profileVoiceStartMutedTitle => get('profile_voice_start_muted_title');
  String get profileVoiceStartMutedSubtitle => get('profile_voice_start_muted_subtitle');
  String get profileVoiceWalkthroughTitle => get('profile_voice_walkthrough_title');
  String get profileVoiceWalkthroughSubtitle => get('profile_voice_walkthrough_subtitle');

  String get profileUnsavedTitle => get('profile_unsaved_title');
  String get profileUnsavedBody => get('profile_unsaved_body');
  String get profileStay => get('profile_stay');
  String get profileDiscard => get('profile_discard');
  String get profileAdditionalInfo => get('profile_additional_info');
  String get profilePronounsTitle => get('profile_pronouns_title');
  String get profilePronounsHeHim => get('profile_pronouns_he_him');
  String get profilePronounsSheHer => get('profile_pronouns_she_her');
  String get profilePronounsTheyThem => get('profile_pronouns_they_them');

  String get profileTabVolunteerHub => get('profile_tab_volunteer_hub');
  String get profileVolunteerCertificationsTitle => get('profile_volunteer_certifications_title');
  String get profileVolunteerCertificationsSubtitle => get('profile_volunteer_certifications_subtitle');
  String get profileCprCertifiedTitle => get('profile_cpr_certified_title');
  String get profileCprCertifiedSubtitle => get('profile_cpr_certified_subtitle');
  String get profileAedCertifiedTitle => get('profile_aed_certified_title');
  String get profileAedCertifiedSubtitle => get('profile_aed_certified_subtitle');
  String get profileCertUploading => get('profile_cert_uploading');
  String get profileUploadCprCert => get('profile_upload_cpr_cert');
  String get profileUploadAedCert => get('profile_upload_aed_cert');
  String get profileCertUploadNoBytes => get('profile_cert_upload_no_bytes');
  String get profileCertUploaded => get('profile_cert_uploaded');
  String profileCertUploadFailed(String e) =>
      get('profile_cert_upload_failed').replaceAll('{e}', e);
  String get help => get('help_screen_title');
  String get profileStatNever => get('profile_stat_never');
  String get profileLoading => get('profile_loading');
  String get profileError => get('profile_error');
  String get profileVolunteerStatsTitle => get('profile_volunteer_stats_title');
  String get profileStatIncidentsResponded => get('profile_stat_incidents_responded');
  String get profileStatTotalLivesSaved => get('profile_stat_total_lives_saved');
  String get profileStatLastIncident => get('profile_stat_last_incident');
  String get profileStatValueCreated => get('profile_stat_value_created');
  String get profileStatValueCreatedHint => get('profile_stat_value_created_hint');

  String get profileHintBloodType => get('profile_hint_blood_type');
  String get profileHintAllergies => get('profile_hint_allergies');
  String get profileHintConditions => get('profile_hint_conditions');
  String get profileHintContactName => get('profile_hint_contact_name');
  String get profileHintRelationship => get('profile_hint_relationship');
  String get profileHintPhone => get('profile_hint_phone');
  String get profileHintContactEmail => get('profile_hint_contact_email');
  String get profileHintMedications => get('profile_hint_medications');
  String get profileHintDonor => get('profile_hint_donor');

  // Home & quick SOS
  String get homeDutyHeading => get('home_duty_heading');
  String homeDutyProgress(int done, int total) =>
      get('home_duty_progress').replaceAll('{done}', '$done').replaceAll('{total}', '$total');
  String get homeMapSemantics => get('home_map_semantics');
  String get homeRecenterMap => get('home_recenter_map');
  String get homeSosLargeFabHint => get('home_sos_large_fab_hint');
  String get homeSosCancelledSnack => get('home_sos_cancelled_snack');
  String get homeSosSentSnack => get('home_sos_sent_snack');
  String get quickSosTitle => get('quick_sos_title');
  String get quickSosSubtitle => get('quick_sos_subtitle');
  String get quickSosPracticeBanner => get('quick_sos_practice_banner');
  String get quickSosSectionWhat => get('quick_sos_section_what');
  String get quickSosSectionSomeoneElse => get('quick_sos_section_someone_else');
  String get quickSosSendNow => get('quick_sos_send_now');
  String get quickSosSelectFirst => get('quick_sos_select_first');
  String get quickSosSectionVictim => get('quick_sos_section_victim');
  String get quickSosVictimSubtitle => get('quick_sos_victim_subtitle');
  String get quickSosSectionPeople => get('quick_sos_section_people');
  String get quickSosYesSomeoneElse => get('quick_sos_yes_someone_else');
  String get quickSosNoForMe => get('quick_sos_no_for_me');
  String get quickSosOtherHint => get('quick_sos_other_hint');
  String get quickSosClose => get('quick_sos_close');
  String get quickSosDrillSubmitDisabled => get('quick_sos_drill_submit_disabled');
  String quickSosFailed(String detail) =>
      get('quick_sos_failed').replaceAll('{detail}', detail);
  String get quickSosCouldNotStart => get('quick_sos_could_not_start');
  String get quickSosVictimConsciousQ => get('quick_sos_victim_conscious_q');
  String get quickSosVictimBreathingQ => get('quick_sos_victim_breathing_q');
  String get quickSosLabelYes => get('quick_sos_label_yes');
  String get quickSosLabelNo => get('quick_sos_label_no');
  String get quickSosLabelUnsure => get('quick_sos_label_unsure');
  String get quickSosPerson => get('quick_sos_person');
  String get quickSosPeople => get('quick_sos_people');
  String get quickSosPeopleThreePlus => get('quick_sos_people_three_plus');

  String get loginTagline => get('login_tagline');
  String get loginSubtitle => get('login_subtitle');
  String get loginContinueGoogle => get('login_continue_google');
  String get loginContinuePhone => get('login_continue_phone');
  String get loginSendCode => get('login_send_code');
  String get loginVerifyLogin => get('login_verify_login');
  String get loginPhoneLabel => get('login_phone_label');
  String get loginPhoneHint => get('login_phone_hint');
  String get loginOtpLabel => get('login_otp_label');
  String get loginBackOptions => get('login_back_options');
  String get loginChangePhone => get('login_change_phone');
  String get loginDrillMode => get('login_drill_mode');
  String get loginDrillSubtitle => get('login_drill_subtitle');
  String get loginDrillSemantics => get('login_drill_semantics');
  String get loginPractiseVictim => get('login_practise_victim');
  String get loginPractiseVolunteer => get('login_practise_volunteer');
  String get loginAdminNote => get('login_admin_note');
  String get loginEmsDashboard => get('login_ems_dashboard');
  String get loginEmergencyOperator => get('login_emergency_operator');

  String get aiAssistPracticeBanner => get('ai_assist_practice_banner');
  String aiAssistRailSemantics(int n, String title) =>
      get('ai_assist_rail_semantics').replaceAll('{n}', '$n').replaceAll('{title}', title);
  String get aiAssistEmergencyToggleOn => get('ai_assist_emergency_toggle_on');
  String get aiAssistEmergencyToggleOff => get('ai_assist_emergency_toggle_off');

  String get dashboardExitDrillTitle => get('dashboard_exit_drill_title');
  String get dashboardExitDrillBody => get('dashboard_exit_drill_body');
  String get dashboardBackLoginTooltip => get('dashboard_back_login_tooltip');
  String get dashboardExitDrillConfirm => get('dashboard_exit_drill_confirm');

  static const Map<String, Map<String, String>> _localizedStrings = {
    // ── English ─────────────────────────────────────────────────────────────
    'en': {
      'app_name': 'EmergencyOS',
      'profile_title': 'Profile & Medical ID',
      'language': 'Language',
      'save_medical_profile': 'Save Medical Profile',
      'critical_medical_info': 'Critical Medical Info',
      'emergency_contacts': 'Emergency Contacts',
      'golden_hour_details': 'Golden Hour Details',
      'sos_lock': 'SOS Lock',
      'top_life_savers': 'Top Life Savers',
      'lives_saved': 'Lives Saved',
      'active_alerts': 'Active Alerts',
      'rank': 'Rank',
      'on_duty': 'ON DUTY',
      'standby': 'STANDBY',
      'sos': 'SOS',
      'call_now': 'CALL NOW',
      'quick_guide': 'QUICK GUIDE',
      'detailed_instructions': 'DETAILED INSTRUCTIONS',
      'red_flags': 'RED FLAGS',
      'cautions': 'CAUTIONS',
      'voice_walkthrough': 'Voice walkthrough',
      'playing': 'Playing...',
      'swipe_next_guide': 'Swipe for next guide',
      'watch_video_guide': 'Watch full video guide',
      'emergency_grid_scan': 'EMERGENCY GRID SCAN',
      'area_telemetry': 'Area Telemetry & Risk Index',
      'report_hazard': 'Report Hazard',
      'todays_duty': "Today's Duty",
      'blood_type': 'Blood Type',
      'allergies': 'Allergies',
      'medical_conditions': 'Medical Conditions',
      'contact_name': 'Primary Contact Name',
      'contact_phone': 'Primary Contact Phone',
      'contact_email': 'Primary Contact Email',
      'relationship': 'Relationship',
      'medications': 'Current Medications',
      'organ_donor': 'Organ Donor Status',
      'good_morning': 'Good Morning,',
      'good_afternoon': 'Good Afternoon,',
      'good_evening': 'Good Evening,',
      'hospitals': 'Hospitals / Trauma',
      'visual_walkthrough': 'Visual walkthrough',
      'lifeline': 'Lifeline',
      'nav_home': 'Home',
      'nav_map': 'Map',
      'nav_grid': 'Grid',
      'nav_profile': 'Profile',
      'map_caching_offline_pct': 'Caching area for offline — {pct}%',
      'map_drill_practice_banner':
          'Practice Grid: pulsing pins = demo active alerts. Use Map filters for layers — not real data.',
      'map_recenter_tooltip': 'Re-center',
      'map_legend_hospital': 'Hospital',
      'map_legend_live_sos_history': 'Live SOS / history',
      'map_legend_past_this_hex': 'Past (this hex)',
      'map_legend_in_area': '{n} in area',
      'map_legend_in_cell': '{n} in cell',
      'map_legend_volunteers_on_duty': 'Volunteers on duty',
      'map_legend_volunteers_in_grid': '{n} in grid',
      'map_legend_responder_scene': 'Responder → scene',
      'map_responder_routes_one': '{n} route',
      'map_responder_routes_many': '{n} routes',
      'map_filters_title': 'Map filters',
      'volunteer_active_browser_location_off':
          'Browser location is off or blocked. You can still view the incident map — enable location in the site settings to show your position.',
      'volunteer_active_location_required':
          'Location permission is required for this consignment.',
      'volunteer_active_map_load_failed': 'Could not load consignment map. {detail}',
      'volunteer_active_no_map_coords':
          'This incident has no map coordinates. Cannot open consignment.',
      'volunteer_active_gps_unavailable':
          'Could not read your GPS yet. Open again outdoors or enable precise location.',
      'volunteer_active_offline_qr_title': 'Offline Location QR',
      'volunteer_active_offline_qr_body':
          'Scan to share incident location access offline.',
      'volunteer_active_close': 'Close',
      'volunteer_active_dispatched_services': 'Dispatched Services',
      'volunteer_active_ambulance': 'Ambulance',
      'volunteer_active_on_scene': 'On Scene',
      'volunteer_active_en_route': 'En Route',
      'volunteer_active_exit_title': 'Exit response window?',
      'volunteer_active_leave_victim': 'Leave this incident view?',
      'volunteer_active_leave_volunteer':
          'You will stop responding to this incident. Your assignment is cleared so the app will not send you back here automatically.',
      'volunteer_active_stay': 'Stay',
      'volunteer_active_exit': 'Exit',
      'volunteer_active_sos_expired':
          'This SOS has expired (1 hour) and was archived.',
      'volunteer_active_back_to_response': 'Back to response',
      'volunteer_active_offline_qr_access': 'Offline QR Access',
      'volunteer_active_hospital_ev_label': 'Hospital & emergency vehicles',
      'volunteer_active_hospital_ev_subtitle':
          'Routed estimates are written to this incident as you approach. Open Maps for real facilities near the pin.',
      'volunteer_active_nearby_hospitals_maps': 'Nearby hospitals in Google Maps',
      'volunteer_active_checklist_saved':
          'Scene checklist saved for dispatch and other responders.',
      'volunteer_active_save_failed': 'Could not save: {detail}',
      'volunteer_active_photo_limit': 'You can upload up to 3 scene photos.',
      'volunteer_active_photo_error': 'Photo error: {detail}',
      'volunteer_active_victim_loading': 'Victim info loading…',
      'sos_active_update_sent_livekit': 'Update sent to Live emergency bridge.',
      'sos_active_update_sent_channel': 'Update sent to incident channel.',
      'sos_active_could_not_send_update': 'Could not send update.',
      'sos_active_voice_text_sent': 'Voice text update sent to the emergency channel.',
      'sos_active_could_not_send_voice': 'Could not send voice update. Try again.',
      'sos_active_voice_update_sent': 'Voice update sent.',
      'sos_active_voice_record_failed':
          'Voice recording failed to send. Try again.',
      'sos_active_routes_to_you': 'Routes to you',
      'sos_active_avg_response_time': 'Avg Response Time:',
      'sos_active_recent_volume': 'Recent Incident Volume:',
      'sos_active_congestion_warning': 'Congestion Warning:',
      'step_prefix': 'Step',
      'highlights_steps': 'Highlights steps one by one',
      'offline_mode': 'OFFLINE MODE — Network disconnected',
      'volunteer': 'Volunteer',
      'unranked': 'Unranked',
      'live': 'Live',
      'you': 'YOU',
      'saved': 'saved',
      'xp_responses': 'XP · {0} responses',
      'duty_monitoring': 'Incoming SOS pop-ups are ON while you are on duty.',
      'turn_on_duty_msg': 'Turn ON DUTY to receive SOS pop-ups.',
      'on_duty_snack': 'ON DUTY — Monitoring for incidents in your area...',
      'off_duty_snack': 'STANDBY — Duty session recorded.',
      'nearby_volunteers_locating': 'Finding your position…',
      'active_volunteers_grid_none': 'No other volunteers in your grid yet',
      'active_volunteers_grid': '{n} active volunteers in your grid',
      'leaderboard_offline': 'LEADERBOARD OFFLINE',
      'leaderboard_offline_sub': 'Syncing paused. Cached scores shown.',
      'leaderboard_empty_primary': 'No response scores yet',
      'leaderboard_empty_secondary':
          'Ranks list volunteers who have accepted an SOS. Past acceptances from archived incidents count here too.',
      'leaderboard_on_duty_fallback_title': 'Volunteers on duty now',
      'leaderboard_on_duty_stat': 'On duty',
      'leaderboard_view_grid': 'Open emergency grid',
      'leaderboard_solo_on_duty':
          "You're on duty. Open the grid to see coverage; other volunteers appear here when they go on duty.",
      'set_sos_pin_first': 'Set SOS PIN first',
      'set_pin_safety_msg': 'For safety, you must set an SOS PIN before creating SOS incidents.',
      'set_pin_now': 'Set PIN now',
      'later': 'Later',
      'emergency_consent_title': 'Emergency data & privacy',
      'emergency_consent_body':
          'When you trigger SOS, EmergencyOS may share your live location, optional profile '
          'medical notes you added in Profile, and voice/updates with volunteers and services '
          'you connect with through the app. '
          'Practice / drill mode does not send a real dispatch.\n\n'
          'You can review or reduce profile data anytime in Profile before an emergency.',
      'consent_not_now': 'Not now',
      'consent_continue': 'I understand — continue',
      'sos_screen_title': 'SOS TRIGGER',
      'sos_hold_banner': 'Only a 3-second hold can trigger SOS',
      'sos_hold_button': 'HOLD 3 SECONDS TO TRIGGER SOS',
      'sos_offline_queued':
          'OFFLINE — SOS QUEUED. Your emergency will be automatically broadcast to responders when connectivity is restored.',
      'sos_semantics_hold_hint':
          'Hold for 3 seconds to trigger SOS emergency alert. Release early to cancel.',
      'sos_starting': 'Starting SOS...',
      'sos_release_to_send': 'Release to send SOS (enables voice guidance).',
      'sos_release_cancel': 'Release early to cancel.',
      'sos_check_connection_retry': 'Check connection and retry.',
      'sos_failed_prefix': 'SOS failed: {detail}',
      'sos_retry': 'RETRY',
      'sos_active_flow_failed': 'Could not start SOS active flow. Please try again.',
      'sos_pin_dispatch_body':
          'For safety, set your SOS PIN in Profile before dispatching SOS.',
      'volunteer_voice_mode_title': 'Choose your volunteer mode',
      'volunteer_voice_mode_subtitle':
          'Before you enter the mission view, pick how you want guidance during this call.',
      'volunteer_voice_mode_audio_title': 'Audio guidance on',
      'volunteer_voice_mode_audio_subtitle':
          'Spoken prompts and updates while you navigate and triage.',
      'volunteer_voice_mode_silent_title': 'Silent (visual-only)',
      'volunteer_voice_mode_silent_subtitle':
          'No text-to-speech; follow on-screen cards and checklists only.',
      'volunteer_voice_mode_footer':
          'You can change this preference later from the SOS and Lifeline settings.',
      'cancel': 'Cancel',
      'continue': 'Continue',
      'close': 'Close',
      'unlock': 'Unlock',
      'pin': 'PIN',
      'save': 'Save',
      'pin_change_title': 'Change SOS PIN',
      'pin_set_title': 'Set SOS PIN',
      'pin_hint_new': 'New PIN',
      'pin_hint_confirm': 'Confirm PIN',
      'pin_error_too_short': 'PIN must be at least 4 digits.',
      'pin_error_mismatch': 'PINs do not match.',
      'wrong_pin': 'Wrong PIN.',
      'wrong_pin_practice': 'Wrong PIN. Practice PIN is {pin}.',
      'no_sos_pin_set': 'No SOS PIN set. Set it in Profile first.',
      'sign_in_to_unlock': 'Sign in to unlock with Profile PIN.',
      'sos_actions_title': 'SOS Actions',
      'sos_actions_cancel_false_alarm': 'Cancel SOS (false alarm)',
      'sos_actions_mark_resolved_safe': 'Mark Resolved (safe)',
      'sos_actions_unlock_and_leave': 'Just unlock & leave (keep SOS running)',
      'sos_other_emergency_title': 'Other emergency',
      'sos_other_emergency_hint': 'Briefly describe what is happening…',
      'sos_other_emergency_value_other': 'Other',
      'sos_other_emergency_value_other_with_detail': 'Other: {detail}',
      'sos_are_you_conscious': 'Are you conscious? Please answer yes or no.',
      'sos_tts_opening_guidance':
          'Your SOS is active. Help is on the way. Follow the spoken prompts and tap to answer.',
      'sos_interview_q1_prompt': 'What is happening? (type of emergency)',
      'sos_interview_q2_prompt': 'Are you safe? How serious is it?',
      'sos_interview_q3_prompt': 'How many people are involved?',
      'sos_chip_cat_accident': 'Accident',
      'sos_chip_cat_medical': 'Medical',
      'sos_chip_cat_hazard': 'Hazard (fire, drowning, etc.)',
      'sos_chip_cat_assault': 'Assault',
      'sos_chip_cat_other': 'Other',
      'sos_chip_safe_critical': 'Critical (life-threatening)',
      'sos_chip_safe_injured': 'Injured but stable',
      'sos_chip_safe_danger': 'Not injured but in danger',
      'sos_chip_safe_safe_now': 'Safe now',
      'sos_chip_people_me': 'Only me',
      'sos_chip_people_two': 'Two',
      'sos_chip_people_many': 'More than two',
      'sos_tts_interview_saved':
          'All victim interview data has been saved. Responders now have detailed information. Consciousness checks will continue every 60 seconds.',
      'sos_tts_map_routes':
          'Open the map tab: solid red is the driving route to the assigned hospital when dispatch sets one, or a short approach path until then. Green shows the assigned volunteer live GPS marker. Stay on the emergency voice channel so responders can hear you.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'No answer. Consciousness check attempt {n} of {max}. We will ask again in one minute.',
      'volunteer_victim_medical_card': 'Victim medical card',
      'volunteer_dispatch_milestone_title': 'Dispatch updates',
      'volunteer_dispatch_milestone_hospital': 'Hospital accepted: {hospital}',
      'volunteer_dispatch_milestone_unit': 'Ambulance unit: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'Ambulance crew: coordinating…',
      'volunteer_dispatch_milestone_en_route': 'Ambulance en route',
      'volunteer_triage_qr_report_title': 'QR or tap report',
      'volunteer_triage_qr_report_subtitle':
          'Scan the code for a handoff payload or tap to save a narrative report on this incident.',
      'volunteer_triage_show_qr': 'Show QR',
      'volunteer_triage_tap_report': 'Tap report',
      'volunteer_triage_qr_title': 'Incident handoff QR',
      'volunteer_triage_qr_body': 'Share this code with receiving staff or EMS for a structured payload.',
      'volunteer_triage_report_saved': 'Report saved under this incident.',
      'volunteer_triage_report_failed': 'Could not save report: ',
      'volunteer_victim_medical_offline_hint':
          'From SOS packet — available from device cache when offline.',
      'volunteer_victim_consciousness_title': 'Consciousness',
      'volunteer_victim_three_questions': 'Initial victim answers',
      'volunteer_major_updates_log': 'Major updates only',
      'volunteer_more_triage_details': 'More triage & vitals',
      'volunteer_more_victim_details': 'More victim details',
      'volunteer_sos_intake_title': 'SOS intake (victim app)',
      'volunteer_show_full_qa': 'Show full Q&A',
      'volunteer_full_qa_sheet_title': 'Victim safety Q&A (full)',
      'volunteer_victim_label_conscious': 'Conscious',
      'volunteer_victim_label_breathing': 'Breathing',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'Escalating to tier {tier}. Trying hospital {hospital}.',
      'volunteer_dispatch_trying_hospital': 'Trying hospital {hospital}.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} has accepted the emergency. Ambulance coordination underway.',
      'volunteer_dispatch_all_hospitals_notified':
          'All hospitals notified. Escalating to emergency services.',
      'sos_dispatch_alerting_nearest_trying':
          'Alerting nearest hospital in your area. Trying {hospital}.',
      'sos_dispatch_escalating_tier_trying':
          'No response. Escalating to tier {tier}. Trying {hospital}.',
      'sos_dispatch_retry_previous_trying':
          'No response from previous hospital. Trying {hospital}.',
      'sos_dispatch_all_hospitals_call_112':
          'All hospitals notified. Please call 112 for emergency services.',
      'profile_synced': 'Synced',
      'profile_not_synced': 'Not synced',
      'profile_saving': 'Saving…',
      'profile_queued_offline': 'Queued (offline)',
      'profile_save_failed': 'Save failed',
      'profile_save_timed_out': 'Save timed out',
      'profile_time_just_now': 'just now',
      'profile_time_min_ago': '{n} min ago',
      'profile_time_hours_ago': '{n}h ago',
      'profile_time_days_ago': '{n}d ago',
      'profile_db_unreachable':
          'Could not reach database. Is Cloud Firestore enabled?',
      'profile_saved_offline_msg': 'Saved locally — will sync when online.',
      'profile_saved_msg': 'Medical info saved successfully.',
      'profile_save_timeout_msg':
          'Save timed out. Please check your internet or Firebase console.',
      'profile_save_error': 'Error saving info: {e}',
      'profile_pin_saved_offline': 'PIN saved locally — will sync when online.',
      'profile_pin_saved': 'SOS PIN saved.',
      'profile_pin_save_error': 'Could not save SOS PIN: {e}',
      'drill_profile_banner':
          'Practice Profile — same layout as live; changes here still save to your account when signed in.',
      'profile_sms_contact_title': 'Send emergency updates to this contact (SMS)',
      'profile_sms_contact_subtitle':
          'When responders accept or ETAs change, EmergencyOS can text your emergency contact.',
      'profile_dispatch_desk_title': 'I am emergency dispatch (join Lifeline WebRTC)',
      'profile_dispatch_desk_subtitle':
          'Enable only for official EMS/dispatch accounts. Lets you join Lifeline as dispatch on active volunteer incidents (not for general volunteers).',
      'profile_pin_status_set': 'PIN is set',
      'profile_pin_status_unset': 'PIN not set',
      'profile_change_pin_btn': 'Change PIN',
      'profile_set_pin_btn': 'Set PIN',
      'profile_pin_exit_note':
          'This PIN is required to exit the SOS Active screen and to cancel/resolve an SOS.',
      'profile_sos_pin_title': 'SOS PIN lock',
      'profile_voice_agent_enable_title': 'Enable Lifeline voice agent',
      'profile_voice_agent_enable_subtitle': 'Shows voice controls on the Lifeline page.',
      'profile_voice_start_muted_title': 'Start with microphone muted',
      'profile_voice_start_muted_subtitle':
          'When connecting, mic stays off until you unmute on the orb.',
      'profile_voice_walkthrough_title': 'Full walkthrough mode',
      'profile_voice_walkthrough_subtitle':
          'Allows Lifeline voice to request SOS (you must still confirm in the app).',
      'profile_unsaved_title': 'Discard changes?',
      'profile_unsaved_body': 'You have unsaved medical profile changes.',
      'profile_stay': 'Keep editing',
      'profile_discard': 'Discard',
      'profile_additional_info': 'Additional medical info',
      'profile_pronouns_title': 'Map avatar pronouns',
      'profile_pronouns_he_him': 'He / him',
      'profile_pronouns_she_her': 'She / her',
      'profile_pronouns_they_them': 'They / them',
      'profile_tab_volunteer_hub': 'Volunteer hub',
      'profile_volunteer_certifications_title': 'Certifications',
      'profile_volunteer_certifications_subtitle':
          'Upload CPR and AED certificates for verification.',
      'profile_cpr_certified_title': 'CPR certified',
      'profile_cpr_certified_subtitle': 'Mark when your CPR training is current.',
      'profile_aed_certified_title': 'AED certified',
      'profile_aed_certified_subtitle': 'Mark when your AED training is current.',
      'profile_cert_uploading': 'Uploading…',
      'profile_upload_cpr_cert': 'Upload CPR certificate',
      'profile_upload_aed_cert': 'Upload AED certificate',
      'profile_cert_upload_no_bytes': 'Could not read the selected file.',
      'profile_cert_uploaded': 'Certificate uploaded.',
      'profile_cert_upload_failed': 'Upload failed: {e}',
      'help_screen_title': 'Help & support',
      'profile_stat_never': 'Never',
      'profile_loading': 'Loading…',
      'profile_error': 'Could not load',
      'profile_volunteer_stats_title': 'Your impact',
      'profile_stat_incidents_responded': 'Incidents responded',
      'profile_stat_total_lives_saved': 'Lives helped (estimate)',
      'profile_stat_last_incident': 'Last response',
      'profile_stat_value_created': 'Member since',
      'profile_stat_value_created_hint': 'Based on your account activity.',
      'profile_hint_blood_type': 'e.g. O+',
      'profile_hint_allergies': 'e.g. Penicillin, Peanuts',
      'profile_hint_conditions': 'e.g. Asthma, Diabetes',
      'profile_hint_contact_name': 'John Doe',
      'profile_hint_relationship': 'e.g. Spouse, Parent',
      'profile_hint_phone': '+1 234 567 8900',
      'profile_hint_contact_email': 'name@example.com',
      'profile_hint_medications': 'e.g. Insulin, Blood Thinners',
      'profile_hint_donor': 'Yes / No',
      'home_duty_heading': "Today's Duty",
      'home_duty_progress': '{done} of {total} prep steps done',
      'home_map_semantics': 'Map showing your area and emergency grid',
      'home_recenter_map': 'Recenter map on my location',
      'home_sos_large_fab_hint': 'Open SOS countdown to send an emergency alert',
      'home_sos_cancelled_snack': 'SOS cancelled.',
      'home_sos_sent_snack': 'SOS sent! Emergency services notified.',
      'quick_sos_title': 'QUICK SOS',
      'quick_sos_subtitle': 'Tap to answer — help arrives faster with details',
      'quick_sos_practice_banner':
          'Practice guided intake — Submit will not create a real SOS. Use Home + 3s hold on the red SOS for the drill scenario.',
      'quick_sos_section_what': "WHAT'S THE EMERGENCY?",
      'quick_sos_section_someone_else': 'ARE YOU TRIGGERING SOS FOR SOMEONE ELSE?',
      'quick_sos_send_now': 'SEND SOS NOW',
      'quick_sos_select_first': 'Select emergency type and confirm',
      'quick_sos_section_victim': 'VICTIM STATUS',
      'quick_sos_victim_subtitle': 'Helps responders prepare the right equipment',
      'quick_sos_section_people': 'HOW MANY PEOPLE NEED HELP?',
      'quick_sos_yes_someone_else': 'YES — for someone else',
      'quick_sos_no_for_me': "NO — it's for me",
      'quick_sos_other_hint': 'Briefly describe your situation...',
      'quick_sos_close': 'Close quick SOS',
      'quick_sos_drill_submit_disabled':
          'Practice shell: intake submit is disabled. Go to Home and press & hold the red SOS button for 3 seconds to open the drill SOS screen.',
      'quick_sos_failed': 'SOS failed: {detail}',
      'quick_sos_could_not_start': 'Could not start SOS. Please try again.',
      'quick_sos_victim_conscious_q': 'Is the person conscious?',
      'quick_sos_victim_breathing_q': 'Is the person breathing?',
      'quick_sos_label_yes': 'Yes',
      'quick_sos_label_no': 'No',
      'quick_sos_label_unsure': 'Unsure',
      'quick_sos_person': 'person',
      'quick_sos_people': 'people',
      'quick_sos_people_three_plus': '3+',
      'login_tagline': "Let's save some lives",
      'login_subtitle':
          'Sign in to report emergencies, coordinate with volunteers, and save lives during the Golden Hour.',
      'login_continue_google': 'Continue with Google',
      'login_continue_phone': 'Continue with Phone',
      'login_send_code': 'Send Verification Code',
      'login_verify_login': 'Verify & Login',
      'login_phone_label': 'Phone Number',
      'login_phone_hint': '+1234567890',
      'login_otp_label': 'Verification Code (OTP)',
      'login_back_options': 'Back to options',
      'login_change_phone': 'Change phone number',
      'login_drill_mode': 'Drill mode',
      'login_drill_subtitle': 'Tap to practise — no real SOS',
      'login_drill_semantics': 'Drill mode, practice without a real emergency',
      'login_practise_victim': 'Practise as victim',
      'login_practise_volunteer': 'Practise as volunteer',
      'login_admin_note':
          'Master admin and operator consoles: no separate admin account — tap below. If you are not signed in yet, we use a lightweight anonymous session only for that console.',
      'login_ems_dashboard': 'EMS Dashboard',
      'login_emergency_operator': 'Emergency service operator login',
      'ai_assist_practice_banner':
          'Practice Lifeline — same guides as live mode; nothing is sent to real dispatch.',
      'ai_assist_rail_semantics': 'Lifeline training level {n}: {title}',
      'ai_assist_emergency_toggle_on': 'Emergency mode on, urgent guidance',
      'ai_assist_emergency_toggle_off': 'Emergency mode off',
      'dashboard_exit_drill_title': 'Exit drill mode?',
      'dashboard_exit_drill_body':
          'You will be signed out of this practice session and returned to the login page.',
      'dashboard_back_login_tooltip': 'Back to login',
      'dashboard_exit_drill_confirm': 'Exit',
    },

    // ── Hindi (हिन्दी) ─────────────────────────────────────────────────────
    'hi': {
      'app_name': 'EmergencyOS',
      'profile_title': 'प्रोफ़ाइल और मेडिकल आईडी',
      'language': 'भाषा',
      'save_medical_profile': 'मेडिकल प्रोफ़ाइल सहेजें',
      'critical_medical_info': 'महत्वपूर्ण चिकित्सा जानकारी',
      'emergency_contacts': 'आपातकालीन संपर्क',
      'golden_hour_details': 'गोल्डन ऑवर विवरण',
      'sos_lock': 'SOS लॉक',
      'top_life_savers': 'शीर्ष जीवन रक्षक',
      'lives_saved': 'बचाई गई जानें',
      'active_alerts': 'सक्रिय अलर्ट',
      'rank': 'रैंक',
      'on_duty': 'ड्यूटी पर',
      'standby': 'स्टैंडबाय',
      'sos': 'SOS',
      'call_now': 'अभी कॉल करें',
      'quick_guide': 'त्वरित गाइड',
      'detailed_instructions': 'विस्तृत निर्देश',
      'red_flags': 'खतरे के संकेत',
      'cautions': 'सावधानियाँ',
      'voice_walkthrough': 'वॉइस वॉकथ्रू',
      'playing': 'चल रहा है...',
      'swipe_next_guide': 'अगली गाइड के लिए स्वाइप करें',
      'watch_video_guide': 'पूरा वीडियो गाइड देखें',
      'emergency_grid_scan': 'आपातकालीन ग्रिड स्कैन',
      'area_telemetry': 'क्षेत्र टेलीमेट्री और जोखिम सूचकांक',
      'report_hazard': 'खतरा रिपोर्ट करें',
      'todays_duty': 'आज की ड्यूटी',
      'blood_type': 'रक्त प्रकार',
      'allergies': 'एलर्जी',
      'medical_conditions': 'चिकित्सा स्थितियाँ',
      'contact_name': 'प्राथमिक संपर्क नाम',
      'contact_phone': 'प्राथमिक संपर्क फ़ोन',
      'relationship': 'संबंध',
      'medications': 'वर्तमान दवाइयाँ',
      'organ_donor': 'अंग दाता स्थिति',
      'good_morning': 'सुप्रभात,',
      'good_afternoon': 'नमस्कार,',
      'good_evening': 'शुभ संध्या,',
      'hospitals': 'अस्पताल / ट्रॉमा',
      'visual_walkthrough': 'विज़ुअल वॉकथ्रू',
      'lifeline': 'लाइफलाइन',
      'nav_home': 'होम',
      'nav_map': 'मानचित्र',
      'nav_grid': 'ग्रिड',
      'nav_profile': 'प्रोफ़ाइल',
      'map_caching_offline_pct': 'ऑफ़लाइन के लिए क्षेत्र कैश हो रहा है — {pct}%',
      'map_drill_practice_banner':
          'अभ्यास ग्रिड: पल्सिंग पिन = डेमो सक्रिय अलर्ट। लेयर्स के लिए मानचित्र फ़िल्टर — वास्तविक डेटा नहीं।',
      'map_recenter_tooltip': 'फिर केंद्रित करें',
      'map_legend_hospital': 'अस्पताल',
      'map_legend_live_sos_history': 'लाइव SOS / इतिहास',
      'map_legend_past_this_hex': 'पिछला (यह हेक्स)',
      'map_legend_in_area': '{n} क्षेत्र में',
      'map_legend_in_cell': '{n} सेल में',
      'map_legend_volunteers_on_duty': 'ड्यूटी पर स्वयंसेवक',
      'map_legend_volunteers_in_grid': 'ग्रिड में {n}',
      'map_legend_responder_scene': 'प्रतिक्रिया → दृश्य',
      'map_responder_routes_one': '{n} मार्ग',
      'map_responder_routes_many': '{n} मार्ग',
      'map_filters_title': 'मानचित्र फ़िल्टर',
      'volunteer_active_browser_location_off':
          'ब्राउज़र लोकेशन बंद या ब्लॉक है। आप फिर भी घटना मानचित्र देख सकते हैं — अपनी स्थिति दिखाने के लिए साइट सेटिंग में लोकेशन चालू करें।',
      'volunteer_active_location_required': 'इस कंसाइनमेंट के लिए स्थान अनुमति आवश्यक है।',
      'volunteer_active_map_load_failed': 'कंसाइनमेंट मानचित्र लोड नहीं हो सका। {detail}',
      'volunteer_active_no_map_coords': 'इस घटना के मानचित्र निर्देशांक नहीं हैं। कंसाइनमेंट नहीं खोल सकते।',
      'volunteer_active_gps_unavailable':
          'अभी GPS नहीं पढ़ सके। बाहर खोलें या सटीक स्थान चालू करें।',
      'volunteer_active_offline_qr_title': 'ऑफ़लाइन स्थान QR',
      'volunteer_active_offline_qr_body': 'ऑफ़लाइन घटना स्थान पहुँच साझा करने के लिए स्कैन करें।',
      'volunteer_active_close': 'बंद करें',
      'volunteer_active_dispatched_services': 'भेजी गई सेवाएँ',
      'volunteer_active_ambulance': 'एम्बुलेंस',
      'volunteer_active_on_scene': 'मौके पर',
      'volunteer_active_en_route': 'रास्ते में',
      'volunteer_active_exit_title': 'प्रतिक्रिया विंडो बंद करें?',
      'volunteer_active_leave_victim': 'इस घटना दृश्य से बाहर निकलें?',
      'volunteer_active_leave_volunteer':
          'आप इस घटना पर प्रतिक्रिया बंद कर देंगे। असाइनमेंट साफ़ हो जाएगा ताकि ऐप आपको यहाँ वापस न भेजे।',
      'volunteer_active_stay': 'रुकें',
      'volunteer_active_exit': 'बाहर निकलें',
      'volunteer_active_sos_expired': 'यह SOS समाप्त (1 घंटा) हो चुका है और संग्रहीत किया गया।',
      'volunteer_active_back_to_response': 'प्रतिक्रिया पर वापस',
      'volunteer_active_offline_qr_access': 'ऑफ़लाइन QR पहुँच',
      'volunteer_active_hospital_ev_label': 'अस्पताल और आपात वाहन',
      'volunteer_active_hospital_ev_subtitle':
          'जैसे-जैसे आप पास आते हैं, मार्ग अनुमान इस घटना में लिखे जाते हैं। पिन के पास वास्तविक सुविधाओं के लिए मानचित्र खोलें।',
      'volunteer_active_nearby_hospitals_maps': 'Google मानचित्र में पास के अस्पताल',
      'volunteer_active_checklist_saved': 'दृश्य चेकलिस्ट डिस्पैच और अन्य प्रतिक्रियाकर्ताओं के लिए सहेजी गई।',
      'volunteer_active_save_failed': 'सहेज नहीं सके: {detail}',
      'volunteer_active_photo_limit': 'अधिकतम 3 दृश्य फ़ोटो अपलोड कर सकते हैं।',
      'volunteer_active_photo_error': 'फ़ोटो त्रुटि: {detail}',
      'volunteer_active_victim_loading': 'पीड़ित जानकारी लोड हो रही है…',
      'sos_active_update_sent_livekit': 'लाइव आपातकालीन ब्रिज पर अपडेट भेजा गया।',
      'sos_active_update_sent_channel': 'घटना चैनल पर अपडेट भेजा गया।',
      'sos_active_could_not_send_update': 'अपडेट नहीं भेज सके।',
      'sos_active_voice_text_sent': 'आवाज़ टेक्स्ट अपडेट आपात चैनल पर भेजा गया।',
      'sos_active_could_not_send_voice': 'आवाज़ अपडेट नहीं भेज सके। फिर कोशिश करें।',
      'sos_active_voice_update_sent': 'आवाज़ अपडेट भेजा गया।',
      'sos_active_voice_record_failed': 'आवाज़ रिकॉर्डिंग भेजी नहीं जा सकी। फिर कोशिश करें।',
      'sos_active_routes_to_you': 'आपकी ओर मार्ग',
      'sos_active_avg_response_time': 'औसत प्रतिक्रिया समय:',
      'sos_active_recent_volume': 'हाल की घटना मात्रा:',
      'sos_active_congestion_warning': 'भीड़ चेतावनी:',
      'step_prefix': 'चरण',
      'highlights_steps': 'एक-एक करके चरण दिखाता है',
      'offline_mode': 'ऑफ़लाइन मोड — नेटवर्क डिस्कनेक्ट',
      'volunteer': 'स्वयंसेवक',
      'unranked': 'अनरैंक्ड',
      'live': 'लाइव',
      'you': 'आप',
      'saved': 'बचाए',
      'xp_responses': 'XP · {0} प्रतिक्रियाएँ',
      'duty_monitoring': 'जब आप ड्यूटी पर हैं तो SOS पॉप-अप चालू हैं।',
      'turn_on_duty_msg': 'SOS पॉप-अप प्राप्त करने के लिए ड्यूटी चालू करें।',
      'on_duty_snack': 'ड्यूटी पर — आपके क्षेत्र में घटनाओं की निगरानी...',
      'off_duty_snack': 'स्टैंडबाय — ड्यूटी सत्र दर्ज किया गया।',
      'nearby_volunteers_locating': 'आपकी स्थिति ढूँढ रहे हैं…',
      'active_volunteers_grid_none': 'आपके ग्रिड में अभी कोई अन्य स्वयंसेवक नहीं',
      'active_volunteers_grid': 'आपके ग्रिड में {n} सक्रिय स्वयंसेवक',
      'leaderboard_offline': 'लीडरबोर्ड ऑफ़लाइन',
      'leaderboard_offline_sub': 'सिंकिंग रुकी। कैश्ड स्कोर दिखाए गए।',
      'leaderboard_empty_primary': 'अभी कोई प्रतिक्रिया स्कोर नहीं',
      'leaderboard_empty_secondary':
          'रैंक उन स्वयंसेवकों की है जिन्होंने SOS स्वीकार किया है। संग्रहीत घटनाओं से पुराने स्वीकृति भी गिने जाते हैं।',
      'leaderboard_on_duty_fallback_title': 'अभी ड्यूटी पर स्वयंसेवक',
      'leaderboard_on_duty_stat': 'ड्यूटी पर',
      'leaderboard_view_grid': 'आपातकालीन ग्रिड खोलें',
      'leaderboard_solo_on_duty':
          'आप ड्यूटी पर हैं। कवरेज देखने के लिए ग्रिड खोलें; अन्य स्वयंसेवक ड्यूटी पर आने पर यहाँ दिखेंगे।',
      'set_sos_pin_first': 'पहले SOS पिन सेट करें',
      'set_pin_safety_msg': 'सुरक्षा के लिए, SOS बनाने से पहले पिन सेट करना आवश्यक है।',
      'set_pin_now': 'अभी पिन सेट करें',
      'later': 'बाद में',
      'emergency_consent_title': 'आपातकालीन डेटा और गोपनीयता',
      'emergency_consent_body':
          'जब आप SOS ट्रिगर करते हैं, EmergencyOS आपका लाइव स्थान, प्रोफ़ाइल में जोड़ा वैकल्पिक चिकित्सा विवरण, '
          'और आवाज़/अपडेट उन स्वयंसेवकों और सेवाओं के साथ साझा कर सकता है जिनसे आप ऐप के ज़रिए जुड़ते हैं। '
          'अभ्यास / ड्रिल मोड वास्तविक डिस्पैच नहीं भेजता।\n\n'
          'आपातकाल से पहले कभी भी प्रोफ़ाइल में डेटा देख या कम कर सकते हैं।',
      'consent_not_now': 'अभी नहीं',
      'consent_continue': 'समझ गया — जारी रखें',
      'sos_screen_title': 'SOS ट्रिगर',
      'sos_hold_banner': 'केवल 3 सेकंड दबाए रखने पर SOS चालू होगा',
      'sos_hold_button': 'SOS के लिए 3 सेकंड दबाए रखें',
      'sos_offline_queued':
          'ऑफ़लाइन — SOS कतार में। कनेक्टिविटी लौटने पर आपकी आपातकालीन सूचना स्वतः प्रतिक्रियाकर्ताओं तक पहुँचेगी।',
      'sos_semantics_hold_hint':
          'SOS के लिए 3 सेकंड दबाए रखें। रद्द करने के लिए जल्दी छोड़ें।',
      'sos_starting': 'SOS शुरू हो रहा है...',
      'sos_release_to_send': 'भेजने के लिए छोड़ें (वॉइस गाइड के लिए)।',
      'sos_release_cancel': 'रद्द करने के लिए जल्दी छोड़ें।',
      'sos_check_connection_retry': 'कनेक्शन जाँचें और फिर कोशिश करें।',
      'sos_failed_prefix': 'SOS विफल: {detail}',
      'sos_retry': 'फिर कोशिश',
      'sos_active_flow_failed': 'SOS सक्रिय स्क्रीन शुरू नहीं हो सकी। पुनः प्रयास करें।',
      'sos_pin_dispatch_body':
          'सुरक्षा के लिए, SOS भेजने से पहले प्रोफ़ाइल में अपना SOS पिन सेट करें।',
      'volunteer_voice_mode_title': 'स्वयंसेवक मोड चुनें',
      'volunteer_voice_mode_subtitle':
          'मिशन दृश्य खोलने से पहले चुनें कि इस कॉल के दौरान मार्गदर्शन कैसे चाहिए।',
      'volunteer_voice_mode_audio_title': 'ऑडियो गाइडेंस चालू',
      'volunteer_voice_mode_audio_subtitle':
          'रूट और ट्रायाज के दौरान बोले गए प्रॉम्प्ट और अपडेट।',
      'volunteer_voice_mode_silent_title': 'साइलेंट (केवल विज़ुअल)',
      'volunteer_voice_mode_silent_subtitle':
          'कोई टेक्स्ट-टू-स्पीच नहीं; केवल ऑन-स्क्रीन कार्ड और चेकलिस्ट देखें।',
      'volunteer_voice_mode_footer':
          'आप बाद में SOS और Lifeline सेटिंग्स में यह पसंद बदल सकते हैं।',
      'cancel': 'रद्द',
      'continue': 'जारी रखें',
      'close': 'बंद करें',
      'unlock': 'अनलॉक',
      'pin': 'पिन',
      'save': 'सहेजें',
      'pin_change_title': 'SOS पिन बदलें',
      'pin_set_title': 'SOS पिन सेट करें',
      'pin_hint_new': 'नया पिन',
      'pin_hint_confirm': 'पिन की पुष्टि',
      'pin_error_too_short': 'पिन कम से कम 4 अंक का हो।',
      'pin_error_mismatch': 'पिन मेल नहीं खाते।',
      'wrong_pin': 'गलत पिन।',
      'wrong_pin_practice': 'गलत पिन। अभ्यास पिन {pin} है।',
      'no_sos_pin_set': 'SOS पिन सेट नहीं है। पहले प्रोफ़ाइल में सेट करें।',
      'sign_in_to_unlock': 'प्रोफ़ाइल पिन से अनलॉक करने के लिए साइन इन करें।',
      'sos_actions_title': 'SOS क्रियाएँ',
      'sos_actions_cancel_false_alarm': 'SOS रद्द करें (गलत अलार्म)',
      'sos_actions_mark_resolved_safe': 'समाधान चिह्नित करें (सुरक्षित)',
      'sos_actions_unlock_and_leave': 'सिर्फ अनलॉक करें और बाहर जाएँ (SOS जारी रहे)',
      'sos_other_emergency_title': 'अन्य आपात स्थिति',
      'sos_other_emergency_hint': 'संक्षेप में बताएं क्या हो रहा है…',
      'sos_other_emergency_value_other': 'अन्य',
      'sos_other_emergency_value_other_with_detail': 'अन्य: {detail}',
      'sos_are_you_conscious': 'क्या आप होश में हैं? कृपया हाँ या ना में जवाब दें।',
      'sos_tts_opening_guidance':
          'आपका SOS सक्रिय है। मदद रास्ते में है। बोले गए संकेतों का पालन करें और जवाब देने के लिए टैप करें।',
      'sos_interview_q1_prompt': 'क्या हो रहा है? (आपातकाल का प्रकार)',
      'sos_interview_q2_prompt': 'क्या आप सुरक्षित हैं? यह कितना गंभीर है?',
      'sos_interview_q3_prompt': 'कितने लोग शामिल हैं?',
      'sos_chip_cat_accident': 'दुर्घटना',
      'sos_chip_cat_medical': 'चिकित्सा',
      'sos_chip_cat_hazard': 'खतरा (आग, डूबना, आदि)',
      'sos_chip_cat_assault': 'हमला',
      'sos_chip_cat_other': 'अन्य',
      'sos_chip_safe_critical': 'गंभीर (जानलेवा)',
      'sos_chip_safe_injured': 'घायल लेकिन स्थिर',
      'sos_chip_safe_danger': 'घायल नहीं लेकिन खतरे में',
      'sos_chip_safe_safe_now': 'अब सुरक्षित',
      'sos_chip_people_me': 'केवल मैं',
      'sos_chip_people_two': 'दो',
      'sos_chip_people_many': 'दो से अधिक',
      'sos_tts_interview_saved':
          'सभी पीड़ित साक्षात्कार डेटा सहेज लिया गया। बचावकर्ताओं के पास विस्तृत जानकारी है। हर 60 सेकंड में चेतना जांच जारी रहेगी।',
      'sos_tts_map_routes':
          'मानचित्र टैब खोलें: ठोस लाल असाइन किए गए अस्पताल की सड़क मार्ग है जब डिस्पैच सेट करता है, अन्यथा तब तक एक छोटा पहुँच मार्ग। हरा असाइन किए गए स्वयंसेवक की मार्ग है। आपातकालीन आवाज़ चैनल पर बने रहें ताकि बचावकर्ता आपको सुन सकें।',
      'sos_tts_emergency_contacts_on_file':
          'आपकी प्रोफ़ाइल का आपातकालीन संपर्क इस SOS से जुड़ा है। विकल्प चालू होने पर SMS अपडेट भेजे जा सकते हैं।',
      'sos_tts_conscious_no_answer_attempt':
          'कोई जवाब नहीं। चेतना जांच प्रयास {n} में से {max}। हम एक मिनट में फिर पूछेंगे।',
      'volunteer_victim_medical_card': 'पीड़ित चिकित्सा कार्ड',
      'volunteer_dispatch_milestone_title': 'डिस्पैच अपडेट',
      'volunteer_dispatch_milestone_hospital': 'अस्पताल स्वीकृत: {hospital}',
      'volunteer_dispatch_milestone_unit': 'एम्बुलेंस यूनिट: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'एम्बुलेंस क्रू: समन्वय…',
      'volunteer_dispatch_milestone_en_route': 'एम्बुलेंस रास्ते में',
      'volunteer_triage_qr_report_title': 'QR या टैप रिपोर्ट',
      'volunteer_triage_qr_report_subtitle':
          'हैंडऑफ़ के लिए कोड स्कैन करें या घटना पर रिपोर्ट सहेजने के लिए टैप करें।',
      'volunteer_triage_show_qr': 'QR दिखाएँ',
      'volunteer_triage_tap_report': 'रिपोर्ट',
      'volunteer_triage_qr_title': 'इंसिडेंट हैंडऑफ़ QR',
      'volunteer_triage_qr_body': 'संरचित पेलोड के लिए स्टाफ़ या EMS के साथ साझा करें।',
      'volunteer_triage_report_saved': 'रिपोर्ट इस घटना के तहत सहेजी गई।',
      'volunteer_triage_report_failed': 'रिपोर्ट सहेजी नहीं जा सकी: ',
      'volunteer_victim_medical_offline_hint':
          'SOS पैकेट से — ऑफ़लाइन होने पर डिवाइस कैश से उपलब्ध।',
      'volunteer_victim_consciousness_title': 'चेतना',
      'volunteer_victim_three_questions': 'प्रारंभिक पीड़ित उत्तर',
      'volunteer_major_updates_log': 'केवल प्रमुख अपडेट',
      'volunteer_more_triage_details': 'अधिक ट्रायेज और वाइटल्स',
      'volunteer_more_victim_details': 'अधिक पीड़ित विवरण',
      'volunteer_sos_intake_title': 'SOS इनटेक (पीड़ित ऐप)',
      'volunteer_show_full_qa': 'पूर्ण Q&A देखें',
      'volunteer_full_qa_sheet_title': 'पीड़ित सुरक्षा Q&A (पूर्ण)',
      'volunteer_victim_label_conscious': 'चेतना',
      'volunteer_victim_label_breathing': 'साँस',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'टियर {tier} तक बढ़ा रहे हैं। अस्पताल {hospital} आज़मा रहे हैं।',
      'volunteer_dispatch_trying_hospital': 'अस्पताल {hospital} आज़मा रहे हैं।',
      'volunteer_dispatch_hospital_accepted':
          'अस्पताल {hospital} ने आपात स्थिति स्वीकार कर ली है। एम्बुलेंस समन्वय जारी है।',
      'volunteer_dispatch_all_hospitals_notified':
          'सभी अस्पतालों को सूचित किया गया। आपात सेवाओं तक बढ़ाया जा रहा है।',
      'sos_dispatch_alerting_nearest_trying':
          'आपके क्षेत्र के निकटतम अस्पताल को सूचित किया जा रहा है। {hospital} से संपर्क कर रहे हैं।',
      'sos_dispatch_escalating_tier_trying':
          'कोई जवाब नहीं। टियर {tier} तक बढ़ा रहे हैं। {hospital} आज़मा रहे हैं।',
      'sos_dispatch_retry_previous_trying':
          'पिछले अस्पताल से कोई जवाब नहीं। {hospital} आज़मा रहे हैं।',
      'sos_dispatch_all_hospitals_call_112':
          'सभी अस्पतालों को सूचित किया गया। आपात सेवाओं के लिए कृपया 112 पर कॉल करें।',
      'profile_synced': 'सिंक हो गया',
      'profile_not_synced': 'सिंक नहीं',
      'profile_saving': 'सहेज रहा है…',
      'profile_queued_offline': 'कतार में (ऑफ़लाइन)',
      'profile_save_failed': 'सहेजना विफल',
      'profile_save_timed_out': 'समय समाप्त',
      'profile_time_just_now': 'अभी',
      'profile_time_min_ago': '{n} मि पहले',
      'profile_time_hours_ago': '{n} घं पहले',
      'profile_time_days_ago': '{n} दिन पहले',
      'profile_db_unreachable':
          'डेटाबेस तक नहीं पहुँच सके। क्या Cloud Firestore चालू है?',
      'profile_saved_offline_msg': 'स्थानीय रूप से सहेजा — ऑनलाइन होने पर सिंक होगा।',
      'profile_saved_msg': 'चिकित्सा जानकारी सहेजी गई।',
      'profile_save_timeout_msg':
          'सहेजना समय समाप्त। इंटरनेट या Firebase कंसोल जाँचें।',
      'profile_save_error': 'सहेजने में त्रुटि: {e}',
      'profile_pin_saved_offline': 'पिन स्थानीय सहेजा — ऑनलाइन होने पर सिंक होगा।',
      'profile_pin_saved': 'SOS पिन सहेजा गया।',
      'profile_pin_save_error': 'SOS पिन सहेज नहीं सका: {e}',
      'drill_profile_banner':
          'अभ्यास प्रोफ़ाइल — लेआउट वैसा ही; साइन इन होने पर यहाँ के बदलाव आपके खाते में सहेजे जाते हैं।',
      'profile_sms_contact_title': 'इस संपर्क को आपातकालीन अपडेट भेजें (SMS)',
      'profile_sms_contact_subtitle':
          'जब प्रतिक्रियाकर्ता स्वीकार करें या ETA बदले, EmergencyOS आपके आपातकालीन संपर्क को SMS भेज सकता है।',
      'profile_dispatch_desk_title': 'मैं आपातकालीन डिस्पैच हूँ (Lifeline WebRTC)',
      'profile_dispatch_desk_subtitle':
          'केवल आधिकारिक EMS/डिस्पैच खातों के लिए। सक्रिय स्वयंसेवक घटनाओं पर Lifeline में डिस्पैच के रूप में शामिल होने देता है।',
      'profile_pin_status_set': 'पिन सेट है',
      'profile_pin_status_unset': 'पिन सेट नहीं',
      'profile_change_pin_btn': 'पिन बदलें',
      'profile_set_pin_btn': 'पिन सेट करें',
      'profile_pin_exit_note':
          'SOS सक्रिय स्क्रीन से बाहर निकलने और SOS रद्द/सुलझाने के लिए यह पिन ज़रूरी है।',
      'profile_hint_blood_type': 'उदा. O+',
      'profile_hint_allergies': 'उदा. पेनिसिलिन, मूँगफली',
      'profile_hint_conditions': 'उदा. अस्थमा, मधुमेह',
      'profile_hint_contact_name': 'नाम',
      'profile_hint_relationship': 'उदा. जीवनसाथी, माता-पिता',
      'profile_hint_phone': '+91 98765 43210',
      'profile_hint_medications': 'उदा. इंसुलिन',
      'profile_hint_donor': 'हाँ / नहीं',
      'home_duty_heading': 'आज की ड्यूटी',
      'home_duty_progress': '{done}/{total} पूर्ण',
      'home_map_semantics': 'आपका परिचालन क्षेत्र और वर्तमान स्थान दिखाने वाला मानचित्र',
      'home_recenter_map': 'मानचित्र को अपने स्थान पर केंद्रित करें',
      'home_sos_large_fab_hint': 'आपातकालीन अलर्ट भेजने के लिए SOS उलटी गिनती खोलें',
      'home_sos_cancelled_snack': 'SOS रद्द।',
      'home_sos_sent_snack': 'SOS भेजा गया! आपात सेवाएँ सूचित।',
      'quick_sos_title': 'त्वरित SOS',
      'quick_sos_subtitle': 'उत्तर दें — विवरण के साथ मदद तेज़ी से पहुँचती है',
      'quick_sos_practice_banner':
          'अभ्यास मार्गदर्शित इनटेक — सबमिट वास्तविक SOS नहीं बनाएगा। ड्रिल के लिए होम पर लाल SOS 3 सेकंड दबाएँ।',
      'quick_sos_section_what': 'आपातकाल क्या है?',
      'quick_sos_section_someone_else': 'क्या आप किसी और के लिए SOS ट्रिगर कर रहे हैं?',
      'quick_sos_send_now': 'अभी SOS भेजें',
      'quick_sos_select_first': 'आपातकाल चुनें और पुष्टि करें',
      'quick_sos_section_victim': 'पीड़ित की स्थिति',
      'quick_sos_victim_subtitle': 'प्रतिक्रियाकर्ताओं को सही उपकरण तैयार करने में मदद करता है',
      'quick_sos_section_people': 'कितने लोगों को मदद चाहिए?',
      'quick_sos_yes_someone_else': 'हाँ — किसी और के लिए',
      'quick_sos_no_for_me': 'नहीं — मेरे लिए',
      'quick_sos_other_hint': 'संक्षेप में अपनी स्थिति बताएँ...',
      'quick_sos_close': 'त्वरित SOS बंद करें',
      'quick_sos_drill_submit_disabled':
          'अभ्यास: सबमिट अक्षम। ड्रिल के लिए होम पर लाल SOS 3 सेकंड दबाएँ।',
      'quick_sos_failed': 'SOS विफल: {detail}',
      'quick_sos_could_not_start': 'SOS शुरू नहीं हो सका। पुनः प्रयास करें।',
      'quick_sos_victim_conscious_q': 'क्या व्यक्ति होश में है?',
      'quick_sos_victim_breathing_q': 'क्या व्यक्ति साँस ले रहा है?',
      'quick_sos_label_yes': 'हाँ',
      'quick_sos_label_no': 'नहीं',
      'quick_sos_label_unsure': 'पक्का नहीं',
      'quick_sos_person': 'व्यक्ति',
      'quick_sos_people': 'लोग',
      'quick_sos_people_three_plus': '3+',
      'login_tagline': 'आइए जानें बचाएँ',
      'login_subtitle':
          'आपातकाल रिपोर्ट करें, स्वयंसेवकों के साथ समन्वय करें, गोल्डन ऑवर में जानें बचाएँ।',
      'login_continue_google': 'Google से जारी रखें',
      'login_continue_phone': 'फ़ोन से जारी रखें',
      'login_send_code': 'सत्यापन कोड भेजें',
      'login_verify_login': 'सत्यापित करें और लॉग इन',
      'login_phone_label': 'फ़ोन नंबर',
      'login_phone_hint': '+919876543210',
      'login_otp_label': 'सत्यापन कोड (OTP)',
      'login_back_options': 'विकल्पों पर वापस',
      'login_change_phone': 'फ़ोन नंबर बदलें',
      'login_drill_mode': 'ड्रिल मोड',
      'login_drill_subtitle': 'अभ्यास के लिए टैप करें — कोई वास्तविक SOS नहीं',
      'login_drill_semantics': 'ड्रिल मोड, वास्तविक आपातकाल के बिना अभ्यास',
      'login_practise_victim': 'पीड़ित के रूप में अभ्यास',
      'login_practise_volunteer': 'स्वयंसेवक के रूप में अभ्यास',
      'login_admin_note':
          'मास्टर कंसोल: अलग खाता नहीं — नीचे टैप करें। साइन इन नहीं होने पर हल्का अनाम सत्र।',
      'login_ems_dashboard': 'EMS डैशबोर्ड',
      'login_emergency_operator': 'आपातकालीन सेवा ऑपरेटर लॉग इन',
      'ai_assist_practice_banner':
          'अभ्यास Lifeline — वास्तविक डिस्पैच पर कुछ नहीं जाता।',
      'ai_assist_rail_semantics': 'Lifeline स्तर {n}: {title}',
      'ai_assist_emergency_toggle_on': 'आपातकालीन मोड चालू, तत्काल मार्गदर्शन',
      'ai_assist_emergency_toggle_off': 'आपातकालीन मोड बंद',
      'dashboard_exit_drill_title': 'ड्रिल मोड से बाहर?',
      'dashboard_exit_drill_body':
          'आप अभ्यास सत्र से साइन आउट होंगे और लॉगिन पर लौटेंगे।',
      'dashboard_back_login_tooltip': 'लॉगिन पर वापस',
      'dashboard_exit_drill_confirm': 'बाहर निकलें',
    },

    // ── Tamil (தமிழ்) ──────────────────────────────────────────────────────
    'ta': {
      'app_name': 'EmergencyOS',
      'profile_title': 'சுயவிவரம் & மருத்துவ அடையாளம்',
      'language': 'மொழி',
      'save_medical_profile': 'மருத்துவ விவரம் சேமி',
      'critical_medical_info': 'முக்கிய மருத்துவ தகவல்',
      'emergency_contacts': 'அவசர தொடர்புகள்',
      'golden_hour_details': 'கோல்டன் ஹவர் விவரங்கள்',
      'sos_lock': 'SOS பூட்டு',
      'top_life_savers': 'சிறந்த உயிர் காப்பாளர்கள்',
      'lives_saved': 'காப்பாற்றிய உயிர்கள்',
      'active_alerts': 'செயலில் உள்ள எச்சரிக்கைகள்',
      'rank': 'தரவரிசை',
      'on_duty': 'பணியில்',
      'standby': 'காத்திருப்பு',
      'sos': 'SOS',
      'call_now': 'இப்போது அழைக்கவும்',
      'quick_guide': 'விரைவு வழிகாட்டி',
      'detailed_instructions': 'விரிவான வழிமுறைகள்',
      'red_flags': 'ஆபத்து அறிகுறிகள்',
      'cautions': 'எச்சரிக்கைகள்',
      'voice_walkthrough': 'குரல் வழிகாட்டுதல்',
      'playing': 'இயங்குகிறது...',
      'swipe_next_guide': 'அடுத்த வழிகாட்டிக்கு ஸ்வைப் செய்யவும்',
      'watch_video_guide': 'முழு வீடியோ வழிகாட்டியைப் பாருங்கள்',
      'emergency_grid_scan': 'அவசர கிரிட் ஸ்கேன்',
      'area_telemetry': 'பகுதி டெலிமெட்ரி & ஆபத்து குறியீடு',
      'report_hazard': 'ஆபத்தைப் புகாரளிக்கவும்',
      'todays_duty': 'இன்றைய கடமை',
      'blood_type': 'இரத்த வகை',
      'allergies': 'ஒவ்வாமைகள்',
      'medical_conditions': 'மருத்துவ நிலைகள்',
      'contact_name': 'முதன்மை தொடர்பு பெயர்',
      'contact_phone': 'முதன்மை தொடர்பு எண்',
      'relationship': 'உறவு',
      'medications': 'தற்போதைய மருந்துகள்',
      'organ_donor': 'உறுப்பு தான நிலை',
      'good_morning': 'காலை வணக்கம்,',
      'good_afternoon': 'மதிய வணக்கம்,',
      'good_evening': 'மாலை வணக்கம்,',
      'hospitals': 'மருத்துவமனைகள்',
      'visual_walkthrough': 'காட்சி வழிகாட்டுதல்',
      'lifeline': 'லைஃப்லைன்',
      'nav_home': 'முகப்பு',
      'nav_map': 'வரைபடம்',
      'nav_grid': 'கிரிட்',
      'nav_profile': 'சுயவிவரம்',
      'map_caching_offline_pct': 'ஆஃப்லைனுக்கு பகுதி தற்காலிகச் சேமிப்பு — {pct}%',
      'map_drill_practice_banner':
          'பயிற்சி கிரிட்: துடிக்கும் பின்கள் = டெமோ செயலில் எச்சரிக்கைகள். அடுக்குகளுக்கு வரைபட வடிகட்டிகள் — உண்மையான தரவு அல்ல.',
      'map_recenter_tooltip': 'மீண்டும் மையப்படுத்து',
      'map_legend_hospital': 'மருத்துவமனை',
      'map_legend_live_sos_history': 'நேரடி SOS / வரலாறு',
      'map_legend_past_this_hex': 'கடந்த (இந்த ஹெக்ஸ்)',
      'map_legend_in_area': 'பகுதியில் {n}',
      'map_legend_in_cell': 'செல்லில் {n}',
      'map_legend_volunteers_on_duty': 'கடமையில் தன்னார்வலர்கள்',
      'map_legend_volunteers_in_grid': 'கிரிட்டில் {n}',
      'map_legend_responder_scene': 'பதிலளிப்பாளர் → இடம்',
      'map_responder_routes_one': '{n} பாதை',
      'map_responder_routes_many': '{n} பாதைகள்',
      'map_filters_title': 'வரைபட வடிகட்டிகள்',
      'step_prefix': 'படி',
      'highlights_steps': 'ஒவ்வொன்றாக படிகளை காட்டுகிறது',
      'offline_mode': 'ஆஃப்லைன் — நெட்வொர்க் துண்டிக்கப்பட்டது',
      'volunteer': 'தன்னார்வலர்',
      'unranked': 'தரவரிசை இல்லை',
      'live': 'நேரலை',
      'you': 'நீங்கள்',
      'saved': 'காப்பாற்றியது',
      'xp_responses': 'XP · {0} பதில்கள்',
      'duty_monitoring': 'நீங்கள் பணியில் இருக்கும்போது SOS பாப்-அப்கள் இயக்கத்தில் உள்ளன.',
      'turn_on_duty_msg': 'SOS பாப்-அப்கள் பெற பணியை இயக்கவும்.',
      'on_duty_snack': 'பணியில் — உங்கள் பகுதியில் சம்பவங்களை கண்காணிக்கிறது...',
      'off_duty_snack': 'காத்திருப்பு — பணி அமர்வு பதிவு செய்யப்பட்டது.',
      'leaderboard_offline': 'லீடர்போர்டு ஆஃப்லைன்',
      'leaderboard_offline_sub': 'ஒத்திசைவு நிறுத்தப்பட்டது. கேச் செய்யப்பட்ட மதிப்பெண்கள்.',
      'set_sos_pin_first': 'முதலில் SOS பின் அமைக்கவும்',
      'set_pin_safety_msg': 'பாதுகாப்பிற்காக, SOS உருவாக்கும் முன் பின் அமைக்க வேண்டும்.',
      'set_pin_now': 'இப்போது பின் அமை',
      'later': 'பின்னர்',
      'sos_screen_title': 'SOS',
      'sos_hold_banner': 'அவசரத்தை அனுப்ப 3 வினாடிகள் அழுத்திப் பிடிக்கவும்.',
      'sos_hold_button': 'SOS ஐ அனுப்ப அழுத்திப் பிடிக்கவும்',
      'sos_semantics_hold_hint': 'SOS. அனுப்ப மூன்று வினாடிகள் அழுத்திப் பிடிக்கவும்.',
      'home_duty_heading': 'இன்றைய கடமை',
      'home_duty_progress': '{done}/{total} முடிந்தது',
      'home_map_semantics': 'உங்கள் பகுதி மற்றும் இருப்பிடத்தைக் காட்டும் வரைபடம்',
      'home_recenter_map': 'வரைபடத்தை உங்கள் இருப்பிடத்திற்கு மையப்படுத்து',
      'home_sos_large_fab_hint': 'அவசர எச்சரிக்கைக்கு SOS எண்ணிக்கையைத் திற',
      'home_sos_cancelled_snack': 'SOS ரத்து.',
      'home_sos_sent_snack': 'SOS அனுப்பப்பட்டது! அவசர சேவைகளுக்குத் தெரிவிக்கப்பட்டது.',
      'quick_sos_title': 'விரைவு SOS',
      'quick_sos_subtitle': 'பதிலளிக்கவும் — விவரங்களுடன் உதவி விரைவாக வரும்',
      'quick_sos_practice_banner':
          'பயிற்சி வழிகாட்டப்பட்ட உள்வாங்கல் — சமர்ப்பிப்பு உண்மையான SOS ஐ உருவாக்காது.',
      'quick_sos_section_what': 'அவசரம் என்ன?',
      'quick_sos_section_someone_else': 'வேறொருவருக்காக SOS ஐத் தூண்டுகிறீர்களா?',
      'quick_sos_send_now': 'இப்போது SOS அனுப்பு',
      'quick_sos_select_first': 'அவசரத்தைத் தேர்ந்தெடுத்து உறுதிப்படுத்தவும்',
      'quick_sos_section_victim': 'பாதிக்கப்பட்டவர் நிலை',
      'quick_sos_victim_subtitle': 'பதிலளிப்பவர்கள் சரியான உபகரணங்களைத் தயார் செய்ய உதவுகிறது',
      'quick_sos_section_people': 'எத்தனை பேருக்கு உதவி தேவை?',
      'quick_sos_yes_someone_else': 'ஆம் — வேறொருவருக்காக',
      'quick_sos_no_for_me': 'இல்லை — எனக்காக',
      'quick_sos_other_hint': 'உங்கள் நிலையை சுருக்கமாக விவரிக்கவும்...',
      'quick_sos_close': 'விரைவு SOS மூடு',
      'quick_sos_drill_submit_disabled':
          'பயிற்சி: சமர்ப்பிப்பு முடக்கப்பட்டது. ட்ரிலுக்கு முகப்பில் சிவப்பு SOS 3 வி. அழுத்தவும்.',
      'quick_sos_failed': 'SOS தோல்வி: {detail}',
      'quick_sos_could_not_start': 'SOS தொடங்க முடியவில்லை. மீண்டும் முயலவும்.',
      'quick_sos_victim_conscious_q': 'அந்த நபர் உணர்வுடன் உள்ளாரா?',
      'sos_are_you_conscious':
          'நீங்கள் உணர்வுடன் உள்ளீர்களா? தயவுசெய்து ஆம் அல்லது இல்லை என்று பதிலளிக்கவும்.',
      'sos_tts_opening_guidance':
          'உங்கள் SOS செயலில் உள்ளது. உதவி வருகிறது. பேசும் வழிமுறைகளைப் பின்பற்றி பதிலளிக்க தட்டவும்.',
      'sos_interview_q1_prompt': 'என்ன நடக்கிறது? (அவசர வகை)',
      'sos_interview_q2_prompt': 'நீங்கள் பாதுகாப்பாக உள்ளீர்களா? எவ்வளவு serious?',
      'sos_interview_q3_prompt': 'எத்தனை பேர் ஈடுபட்டுள்ளனர்?',
      'sos_chip_cat_accident': 'விபத்து',
      'sos_chip_cat_medical': 'மருத்துவ',
      'sos_chip_cat_hazard': 'அபாயம் (தீ, மூழ்குதல், முதலியன)',
      'sos_chip_cat_assault': 'தாக்குதல்',
      'sos_chip_cat_other': 'மற்றவை',
      'sos_chip_safe_critical': 'மிக மோசமான (உயிருக்கு ஆபத்து)',
      'sos_chip_safe_injured': 'காயம்; நிலையானது',
      'sos_chip_safe_danger': 'காயமில்லை; ஆனால் ஆபத்தில்',
      'sos_chip_safe_safe_now': 'இப்போது பாதுகாப்பு',
      'sos_chip_people_me': 'நான் மட்டும்',
      'sos_chip_people_two': 'இருவர்',
      'sos_chip_people_many': 'இருவருக்கு மேல்',
      'sos_tts_interview_saved':
          'பாதிக்கப்பட்டவர் பேட்டி தரவு அனைத்தும் சேமிக்கப்பட்டது. மீட்பவர்களுக்கு விவரங்கள் உள்ளன. ஒவ்வொரு 60 வினாடியிலும் உணர்வு சோதனை தொடரும்.',
      'sos_tts_map_routes':
          'வரைபடத் தாவலைத் திறக்கவும்: சிவப்பு ஒதுக்கப்பட்ட மருத்துவமனைக்கு சாலை வழி; இல்லையெனில் அணுகல் பாதை. பச்சை தன்னார்வலர் வழி. அவசர குரல் சேனலில் இருங்கள்.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'பதில் இல்லை. உணர்வு சோதனை {max} இல் {n}. ஒரு நிமிடத்தில் மீண்டும் கேட்கிறோம்.',
      'volunteer_victim_medical_card': 'பாதிக்கப்பட்டவர் மருத்துவ அட்டை',
      'volunteer_dispatch_milestone_title': 'டிஸ்பैச் புதுப்பிப்புகள்',
      'volunteer_dispatch_milestone_hospital': 'மருத்துவமனை ஏற்றுக்கொண்டது: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ஆம்புலன்ஸ் யூனிட்: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ஆம்புலன்ஸ் குழு: ஒருங்கிணைப்பு…',
      'volunteer_dispatch_milestone_en_route': 'ஆம்புலன்ஸ் வழியில்',
      'volunteer_triage_qr_report_title': 'QR அல்லது தட்டவும் அறிக்கை',
      'volunteer_triage_qr_report_subtitle':
          'கையளிப்புக்கு குறியீட்டை ஸ்கேன் செய்யவும் அல்லது சம்பவ அறிக்கையைச் சேமிக்க தட்டவும்.',
      'volunteer_triage_show_qr': 'QR காட்டு',
      'volunteer_triage_tap_report': 'அறிக்கை',
      'volunteer_triage_qr_title': 'சம்பவ கையளிப்பு QR',
      'volunteer_triage_qr_body': 'கட்டமைக்கப்பட்ட தரவுக்கு ஊழியர்கள் அல்லது EMS உடன் பகிரவும்.',
      'volunteer_triage_report_saved': 'அறிக்கை இந்த சம்பவத்தின் கீழ் சேமிக்கப்பட்டது.',
      'volunteer_triage_report_failed': 'அறிக்கையைச் சேமிக்க முடியவில்லை: ',
      'volunteer_victim_medical_offline_hint':
          'SOS பாக்கெட்டிலிருந்து — ஆஃப்லைனில் சாதன கேச் மூலம்.',
      'volunteer_victim_consciousness_title': 'உணர்வு',
      'volunteer_victim_three_questions': 'ஆரம்ப பாதிக்கப்பட்டவர் பதில்கள்',
      'volunteer_major_updates_log': 'முக்கியமான புதுப்பிப்புகள் மட்டும்',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'அடுக்கு {tier} வரை உயர்த்துகிறோம். மருத்துவமனை {hospital} முயற்சிக்கிறோம்.',
      'volunteer_dispatch_trying_hospital': 'மருத்துவமனை {hospital} முயற்சிக்கிறோம்.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} அவசரத்தை ஏற்றது. ஆம்புலன்ஸ் ஒருங்கிணைப்பு நடக்கிறது.',
      'volunteer_dispatch_all_hospitals_notified':
          'அனைத்து மருத்துவமனைகளுக்கும் அறிவிக்கப்பட்டது. அவசர சேவைகளுக்கு மேலே செல்கிறோம்.',
      'sos_dispatch_alerting_nearest_trying':
          'உங்கள் பகுதியில் அருகிலுள்ள மருத்துவமனையை அழைக்கிறோம். {hospital} முயற்சிக்கிறோம்.',
      'sos_dispatch_escalating_tier_trying':
          'பதில் இல்லை. அடுக்கு {tier} வரை உயர்த்துகிறோம். {hospital} முயற்சிக்கிறோம்.',
      'sos_dispatch_retry_previous_trying':
          'முந்தைய மருத்துவமனையில் இருந்து பதில் இல்லை. {hospital} முயற்சிக்கிறோம்.',
      'sos_dispatch_all_hospitals_call_112':
          'அனைத்து மருத்துவமனைகளுக்கும் அறிவிக்கப்பட்டது. அவசர சேவைகளுக்கு 112 ஐ அழைக்கவும்.',
      'quick_sos_victim_breathing_q': 'அந்த நபர் சுவாசிக்கிறாரா?',
      'quick_sos_label_yes': 'ஆம்',
      'quick_sos_label_no': 'இல்லை',
      'quick_sos_label_unsure': 'உறுதியில்லை',
      'quick_sos_person': 'நபர்',
      'quick_sos_people': 'நபர்கள்',
      'quick_sos_people_three_plus': '3+',
      'login_tagline': 'உயிர்களைக் காப்போம்',
      'login_subtitle':
          'அவசரங்களைப் புகாரளிக்கவும், தன்னார்வலர்களுடன் ஒருங்கிணைக்கவும், கோல்டன் ஹவரில் உயிர்களைக் காப்பாற்றவும்.',
      'login_continue_google': 'Google உடன் தொடரவும்',
      'login_continue_phone': 'தொலைபேசியுடன் தொடரவும்',
      'login_send_code': 'சரிபார்ப்புக் குறியீட்டை அனுப்பு',
      'login_verify_login': 'சரிபார்த்து உள்நுழை',
      'login_phone_label': 'தொலைபேசி எண்',
      'login_phone_hint': '+919876543210',
      'login_otp_label': 'சரிபார்ப்புக் குறியீடு (OTP)',
      'login_back_options': 'விருப்பங்களுக்குத் திரும்பு',
      'login_change_phone': 'தொலைபேசி எண்ணை மாற்று',
      'login_drill_mode': 'பயிற்சி பயன்முறை',
      'login_drill_subtitle': 'பயிற்சிக்குத் தட்டவும் — உண்மையான SOS இல்லை',
      'login_drill_semantics': 'பயிற்சி பயன்முறை, உண்மையான அவசரம் இல்லாமல்',
      'login_practise_victim': 'பாதிக்கப்பட்டவராக பயிற்சி',
      'login_practise_volunteer': 'தன்னார்வலராக பயிற்சி',
      'login_admin_note':
          'முதன்மை கன்சோல்: தனி கணக்கு இல்லை — கீழே தட்டவும். உள்நுழையாவிட்டால் இலகுவான அநாமதேய அமர்வு.',
      'login_ems_dashboard': 'EMS டாஷ்போர்டு',
      'login_emergency_operator': 'அவசர சேவை ஆபரேட்டர் உள்நுழைவு',
      'ai_assist_practice_banner':
          'பயிற்சி Lifeline — உண்மையான டிஸ்பैச் எதுவும் அனுப்பப்படாது.',
      'ai_assist_rail_semantics': 'Lifeline நிலை {n}: {title}',
      'ai_assist_emergency_toggle_on': 'அவசர பயன்முறை இயக்கம், அவசர வழிகாட்டுதல்',
      'ai_assist_emergency_toggle_off': 'அவசர பயன்முறை முடக்கம்',
      'dashboard_exit_drill_title': 'பயிற்சி பயன்முறையிலிருந்து வெளியேற?',
      'dashboard_exit_drill_body':
          'இந்த பயிற்சி அமர்விலிருந்து வெளியேறி உள்நுழைவு பக்கத்திற்குத் திரும்புவீர்கள்.',
      'dashboard_back_login_tooltip': 'உள்நுழைவுக்குத் திரும்பு',
    },

    // ── Telugu (తెలుగు) ────────────────────────────────────────────────────
    'te': {
      'app_name': 'EmergencyOS',
      'profile_title': 'ప్రొఫైల్ & వైద్య గుర్తింపు',
      'language': 'భాష',
      'save_medical_profile': 'వైద్య ప్రొఫైల్ సేవ్ చేయండి',
      'critical_medical_info': 'కీలక వైద్య సమాచారం',
      'emergency_contacts': 'అత్యవసర సంప్రదింపులు',
      'golden_hour_details': 'గోల్డెన్ అవర్ వివరాలు',
      'sos_lock': 'SOS లాక్',
      'top_life_savers': 'అగ్ర ప్రాణ రక్షకులు',
      'lives_saved': 'రక్షించిన ప్రాణాలు',
      'active_alerts': 'యాక్టివ్ అలర్ట్‌లు',
      'rank': 'ర్యాంక్',
      'on_duty': 'డ్యూటీలో',
      'standby': 'స్టాండ్‌బై',
      'sos': 'SOS',
      'call_now': 'ఇప్పుడు కాల్ చేయండి',
      'quick_guide': 'త్వరిత గైడ్',
      'detailed_instructions': 'వివరమైన సూచనలు',
      'red_flags': 'ప్రమాద సంకేతాలు',
      'cautions': 'జాగ్రత్తలు',
      'voice_walkthrough': 'వాయిస్ వాక్‌త్రూ',
      'playing': 'ప్లే అవుతోంది...',
      'swipe_next_guide': 'తదుపరి గైడ్ కోసం స్వైప్ చేయండి',
      'watch_video_guide': 'పూర్తి వీడియో గైడ్ చూడండి',
      'emergency_grid_scan': 'అత్యవసర గ్రిడ్ స్కాన్',
      'area_telemetry': 'ప్రాంత టెలిమెట్రీ & ప్రమాద సూచిక',
      'report_hazard': 'ప్రమాదాన్ని నివేదించండి',
      'todays_duty': 'నేటి డ్యూటీ',
      'blood_type': 'రక్త రకం',
      'allergies': 'అలర్జీలు',
      'medical_conditions': 'వైద్య పరిస్థితులు',
      'contact_name': 'ప్రాథమిక సంప్రదింపు పేరు',
      'contact_phone': 'ప్రాథమిక సంప్రదింపు ఫోన్',
      'relationship': 'సంబంధం',
      'medications': 'ప్రస్తుత మందులు',
      'organ_donor': 'అవయవ దాత స్థితి',
      'good_morning': 'శుభోదయం,',
      'good_afternoon': 'శుభ మధ్యాహ్నం,',
      'good_evening': 'శుభ సాయంత్రం,',
      'hospitals': 'ఆసుపత్రులు',
      'visual_walkthrough': 'విజువల్ వాక్‌త్రూ',
      'lifeline': 'లైఫ్‌లైన్',
      'nav_home': 'హోమ్',
      'nav_map': 'మ్యాప్',
      'nav_grid': 'గ్రిడ్',
      'nav_profile': 'ప్రొఫైల్',
      'map_caching_offline_pct': 'ఆఫ్‌లైన్ కోసం ప్రాంతం క్యాష్ — {pct}%',
      'map_drill_practice_banner':
          'ప్రాక్టీస్ గ్రిడ్: పల్సింగ్ పిన్‌లు = డెమో సక్రియ హెచ్చరికలు. పొరల కోసం మ్యాప్ ఫిల్టర్‌లు — నిజమైన డేటా కాదు.',
      'map_recenter_tooltip': 'మళ్లీ కేంద్రీకరించు',
      'map_legend_hospital': 'ఆసుపత్రి',
      'map_legend_live_sos_history': 'లైవ్ SOS / చరిత్ర',
      'map_legend_past_this_hex': 'గత (ఈ హెక్స్)',
      'map_legend_in_area': 'ప్రాంతంలో {n}',
      'map_legend_in_cell': 'సెల్‌లో {n}',
      'map_legend_volunteers_on_duty': 'డ్యూటీలో స్వయంసేవకులు',
      'map_legend_volunteers_in_grid': 'గ్రిడ్‌లో {n}',
      'map_legend_responder_scene': 'ప్రతిస్పందిక → దృశ్యం',
      'map_responder_routes_one': '{n} మార్గం',
      'map_responder_routes_many': '{n} మార్గాలు',
      'map_filters_title': 'మ్యాప్ ఫిల్టర్‌లు',
      'step_prefix': 'దశ',
      'highlights_steps': 'ఒక్కొక్కటిగా దశలను చూపిస్తుంది',
      'offline_mode': 'ఆఫ్‌లైన్ — నెట్‌వర్క్ డిస్‌కనెక్ట్',
      'volunteer': 'వాలంటీర్',
      'unranked': 'ర్యాంక్ లేదు',
      'live': 'లైవ్',
      'you': 'మీరు',
      'saved': 'రక్షించారు',
      'xp_responses': 'XP · {0} ప్రతిస్పందనలు',
      'duty_monitoring': 'మీరు డ్యూటీలో ఉన్నప్పుడు SOS పాప్-అప్‌లు ఆన్ చేయబడ్డాయి.',
      'turn_on_duty_msg': 'SOS పాప్-అప్‌లు అందుకోవడానికి డ్యూటీ ఆన్ చేయండి.',
      'on_duty_snack': 'డ్యూటీలో — మీ ప్రాంతంలో సంఘటనలను పర్యవేక్షిస్తోంది...',
      'off_duty_snack': 'స్టాండ్‌బై — డ్యూటీ సెషన్ రికార్డ్ చేయబడింది.',
      'leaderboard_offline': 'లీడర్‌బోర్డ్ ఆఫ్‌లైన్',
      'leaderboard_offline_sub': 'సింక్ ఆగింది. కాష్ స్కోర్‌లు చూపబడ్డాయి.',
      'set_sos_pin_first': 'ముందు SOS పిన్ సెట్ చేయండి',
      'set_pin_safety_msg': 'భద్రత కోసం, SOS సృష్టించే ముందు పిన్ సెట్ చేయాలి.',
      'set_pin_now': 'ఇప్పుడు పిన్ సెట్ చేయండి',
      'later': 'తర్వాత',
      'sos_are_you_conscious':
          'మీరు అవగాహనలో ఉన్నారా? దయచేసి అవును లేదా కాదు అని సమాధానం ఇవ్వండి.',
      'sos_tts_opening_guidance':
          'మీ SOS సక్రియంగా ఉంది. సహాయం మార్గంలో ఉంది. మాటల సూచనలను అనుసరించి స్పందించడానికి టాప్ చేయండి.',
      'sos_interview_q1_prompt': 'ఏమి జరుగుతోంది? (అత్యవసర రకం)',
      'sos_interview_q2_prompt': 'మీరు సురక్షితంగా ఉన్నారా? ఎంత తీవ్రం?',
      'sos_interview_q3_prompt': 'ఎంత మంది పాల్గొన్నారు?',
      'sos_chip_cat_accident': 'ప్రమాదం',
      'sos_chip_cat_medical': 'వైద్యం',
      'sos_chip_cat_hazard': 'అపాయం (నిప్పు, మునిగిపోవడం మొదలైనవి)',
      'sos_chip_cat_assault': 'దాడి',
      'sos_chip_cat_other': 'ఇతర',
      'sos_chip_safe_critical': 'తీవ్ర (ప్రాణాంతకం)',
      'sos_chip_safe_injured': 'గాయపడింది కానీ స్థిరం',
      'sos_chip_safe_danger': 'గాయం లేదు కానీ ప్రమాదంలో',
      'sos_chip_safe_safe_now': 'ఇప్పుడు సురక్షితం',
      'sos_chip_people_me': 'నేను మాత్రమే',
      'sos_chip_people_two': 'ఇద్దరు',
      'sos_chip_people_many': 'ఇద్దరికంటే ఎక్కువ',
      'sos_tts_interview_saved':
          'బాధిత ఇంటర్వ్యూ డేటా అంతా సేవ్ చేయబడింది. రెస్పాండర్లకు వివరాలు ఉన్నాయి. ప్రతి 60 సెకన్లకు అవగాహన తనిఖీ కొనసాగుతుంది.',
      'sos_tts_map_routes':
          'మ్యాప్ ట్యాబ్ తెరవండి: ఎరుపు కేటాయించిన ఆసుపత్రికి రోడ్ మార్గం లేదా సమీప మార్గం; ఆకుపచ్చ వాలంటీర్ మార్గం. అత్యవసర వాయిస్ ఛానెల్‌లో ఉండండి.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'సమాధానం లేదు. అవగాహన తనిఖీ {max}లో {n}. ఒక నిమిషంలో మళ్లీ అడుగుతాము.',
      'volunteer_victim_medical_card': 'బాధిత వైద్య కార్డ్',
      'volunteer_dispatch_milestone_title': 'డిస్పాచ్ నవీకరణలు',
      'volunteer_dispatch_milestone_hospital': 'ఆసుపత్రి అంగీకరించింది: {hospital}',
      'volunteer_dispatch_milestone_unit': 'అంబులెన్స్ యూనిట్: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'అంబులెన్స్ క్రూ: సమన్వయం…',
      'volunteer_dispatch_milestone_en_route': 'అంబులెన్స్ మార్గంలో',
      'volunteer_triage_qr_report_title': 'QR లేదా నొక్కండి నివేదిక',
      'volunteer_triage_qr_report_subtitle':
          'హ్యాండ్‌ఆఫ్ కోసం కోడ్ స్కాన్ చేయండి లేదా నివేదికను సేవ్ చేయడానికి నొక్కండి.',
      'volunteer_triage_show_qr': 'QR చూపు',
      'volunteer_triage_tap_report': 'నివేదిక',
      'volunteer_triage_qr_title': 'ఘటన హ్యాండ్‌ఆఫ్ QR',
      'volunteer_triage_qr_body': 'జోడించిన సిబ్బంది లేదా EMSతో పంచుకోండి.',
      'volunteer_triage_report_saved': 'నివేదిక ఈ ఘటన కింద సేవ్ చేయబడింది.',
      'volunteer_triage_report_failed': 'నివేదికను సేవ్ చేయలేకపోయాము: ',
      'volunteer_victim_medical_offline_hint':
          'SOS ప్యాకెట్ నుండి — ఆఫ్‌లైన్‌లో పరికర కాష్ నుండి అందుబాటులో.',
      'volunteer_victim_consciousness_title': 'అవగాహన',
      'volunteer_victim_three_questions': 'ప్రారంభ బాధిత సమాధానాలు',
      'volunteer_major_updates_log': 'ప్రధాన అప్‌డేట్‌లు మాత్రమే',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'టియర్ {tier} వరకు పెంచుతున్నాము. ఆసుపత్రి {hospital} ప్రయత్నిస్తున్నాము.',
      'volunteer_dispatch_trying_hospital': 'ఆసుపత్రి {hospital} ప్రయత్నిస్తున్నాము.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} అత్యవసరాన్ని అంగీకరించింది. అంబులెన్స్ సమన్వయం ప్రగతిలో ఉంది.',
      'volunteer_dispatch_all_hospitals_notified':
          'అన్ని ఆసుపత్రులకు తెలియజేశాము. అత్యవసర సేవలకు పైకి పంపుతున్నాము.',
      'sos_dispatch_alerting_nearest_trying':
          'మీ ప్రాంతంలో సమీప ఆసుపత్రిని అలర్ట్ చేస్తున్నాము. {hospital} ప్రయత్నిస్తున్నాము.',
      'sos_dispatch_escalating_tier_trying':
          'ప్రతిస్పందన లేదు. టియర్ {tier} వరకు పెంచుతున్నాము. {hospital} ప్రయత్నిస్తున్నాము.',
      'sos_dispatch_retry_previous_trying':
          'మునపటి ఆసుపత్రి నుండి ప్రతిస్పందన లేదు. {hospital} ప్రయత్నిస్తున్నాము.',
      'sos_dispatch_all_hospitals_call_112':
          'అన్ని ఆసుపత్రులకు తెలియజేశాము. అత్యవసర సేవలకు దయచేసి 112 కు కాల్ చేయండి.',
    },

    // ── Kannada (ಕನ್ನಡ) ────────────────────────────────────────────────────
    'kn': {
      'app_name': 'EmergencyOS',
      'profile_title': 'ಪ್ರೊಫೈಲ್ & ವೈದ್ಯಕೀಯ ಗುರುತು',
      'language': 'ಭಾಷೆ',
      'save_medical_profile': 'ವೈದ್ಯಕೀಯ ಪ್ರೊಫೈಲ್ ಉಳಿಸಿ',
      'critical_medical_info': 'ನಿರ್ಣಾಯಕ ವೈದ್ಯಕೀಯ ಮಾಹಿತಿ',
      'emergency_contacts': 'ತುರ್ತು ಸಂಪರ್ಕಗಳು',
      'golden_hour_details': 'ಗೋಲ್ಡನ್ ಅವರ್ ವಿವರಗಳು',
      'sos_lock': 'SOS ಲಾಕ್',
      'top_life_savers': 'ಅಗ್ರ ಜೀವ ರಕ್ಷಕರು',
      'lives_saved': 'ಉಳಿಸಿದ ಜೀವಗಳು',
      'active_alerts': 'ಸಕ್ರಿಯ ಎಚ್ಚರಿಕೆಗಳು',
      'rank': 'ಶ್ರೇಣಿ',
      'on_duty': 'ಕರ್ತವ್ಯದಲ್ಲಿ',
      'standby': 'ಸ್ಟ್ಯಾಂಡ್‌ಬೈ',
      'sos': 'SOS',
      'call_now': 'ಈಗ ಕರೆ ಮಾಡಿ',
      'quick_guide': 'ತ್ವರಿತ ಮಾರ್ಗದರ್ಶಿ',
      'detailed_instructions': 'ವಿವರವಾದ ಸೂಚನೆಗಳು',
      'red_flags': 'ಅಪಾಯ ಸಂಕೇತಗಳು',
      'cautions': 'ಎಚ್ಚರಿಕೆಗಳು',
      'voice_walkthrough': 'ಧ್ವನಿ ಮಾರ್ಗದರ್ಶನ',
      'playing': 'ನುಡಿಸುತ್ತಿದೆ...',
      'swipe_next_guide': 'ಮುಂದಿನ ಮಾರ್ಗದರ್ಶಿಗಾಗಿ ಸ್ವೈಪ್ ಮಾಡಿ',
      'watch_video_guide': 'ಪೂರ್ಣ ವೀಡಿಯೊ ಮಾರ್ಗದರ್ಶಿ ನೋಡಿ',
      'emergency_grid_scan': 'ತುರ್ತು ಗ್ರಿಡ್ ಸ್ಕ್ಯಾನ್',
      'area_telemetry': 'ಪ್ರದೇಶ ಟೆಲಿಮೆಟ್ರಿ & ಅಪಾಯ ಸೂಚಿ',
      'report_hazard': 'ಅಪಾಯ ವರದಿ ಮಾಡಿ',
      'todays_duty': 'ಇಂದಿನ ಕರ್ತವ್ಯ',
      'blood_type': 'ರಕ್ತದ ಗುಂಪು',
      'allergies': 'ಅಲರ್ಜಿಗಳು',
      'medical_conditions': 'ವೈದ್ಯಕೀಯ ಸ್ಥಿತಿಗಳು',
      'contact_name': 'ಪ್ರಾಥಮಿಕ ಸಂಪರ್ಕ ಹೆಸರು',
      'contact_phone': 'ಪ್ರಾಥಮಿಕ ಸಂಪರ್ಕ ಫೋನ್',
      'relationship': 'ಸಂಬಂಧ',
      'medications': 'ಪ್ರಸ್ತುತ ಔಷಧಗಳು',
      'organ_donor': 'ಅಂಗ ದಾನಿ ಸ್ಥಿತಿ',
      'good_morning': 'ಶುಭೋದಯ,',
      'good_afternoon': 'ಶುಭ ಮಧ್ಯಾಹ್ನ,',
      'good_evening': 'ಶುಭ ಸಂಜೆ,',
      'hospitals': 'ಆಸ್ಪತ್ರೆಗಳು',
      'visual_walkthrough': 'ದೃಶ್ಯ ಮಾರ್ಗದರ್ಶನ',
      'lifeline': 'ಲೈಫ್‌ಲೈನ್',
      'nav_home': 'ಹೋಮ್',
      'nav_map': 'ನಕ್ಷೆ',
      'nav_grid': 'ಗ್ರಿಡ್',
      'nav_profile': 'ಪ್ರೊಫೈಲ್',
      'map_caching_offline_pct': 'ಆಫ್‌ಲೈನ್‌ಗಾಗಿ ಪ್ರದೇಶ ಕ್ಯಾಶ್ — {pct}%',
      'map_drill_practice_banner':
          'ಅಭ್ಯಾಸ ಗ್ರಿಡ್: ಪಲ್ಸಿಂಗ್ ಪಿನ್‌ಗಳು = ಡೆಮೋ ಸಕ್ರಿಯ ಎಚ್ಚರಿಕೆಗಳು. ಪದರಗಳಿಗೆ ನಕ್ಷೆ ಫಿಲ್ಟರ್‌ಗಳು — ನಿಜವಾದ ಡೇಟಾ ಅಲ್ಲ.',
      'map_recenter_tooltip': 'ಮತ್ತೆ ಕೇಂದ್ರೀಕರಿಸಿ',
      'map_legend_hospital': 'ಆಸ್ಪತ್ರೆ',
      'map_legend_live_sos_history': 'ಲೈವ್ SOS / ಇತಿಹಾಸ',
      'map_legend_past_this_hex': 'ಹಿಂದಿನ (ಈ ಹೆಕ್ಸ್)',
      'map_legend_in_area': 'ಪ್ರದೇಶದಲ್ಲಿ {n}',
      'map_legend_in_cell': 'ಸೆಲ್‌ನಲ್ಲಿ {n}',
      'map_legend_volunteers_on_duty': 'ಕರ್ತವ್ಯದಲ್ಲಿ ಸ್ವಯಂಸೇವಕರು',
      'map_legend_volunteers_in_grid': 'ಗ್ರಿಡ್‌ನಲ್ಲಿ {n}',
      'map_legend_responder_scene': 'ಪ್ರತಿಕ್ರಿಯೆ → ದೃಶ್ಯ',
      'map_responder_routes_one': '{n} ಮಾರ್ಗ',
      'map_responder_routes_many': '{n} ಮಾರ್ಗಗಳು',
      'map_filters_title': 'ನಕ್ಷೆ ಫಿಲ್ಟರ್‌ಗಳು',
      'step_prefix': 'ಹಂತ',
      'highlights_steps': 'ಒಂದೊಂದಾಗಿ ಹಂತಗಳನ್ನು ತೋರಿಸುತ್ತದೆ',
      'offline_mode': 'ಆಫ್‌ಲೈನ್ — ನೆಟ್‌ವರ್ಕ್ ಸಂಪರ್ಕ ಕಡಿತ',
      'volunteer': 'ಸ್ವಯಂಸೇವಕ',
      'unranked': 'ಶ್ರೇಣಿ ಇಲ್ಲ',
      'live': 'ಲೈವ್',
      'you': 'ನೀವು',
      'saved': 'ಉಳಿಸಿದ',
      'xp_responses': 'XP · {0} ಪ್ರತಿಕ್ರಿಯೆಗಳು',
      'duty_monitoring': 'ನೀವು ಕರ್ತವ್ಯದಲ್ಲಿರುವಾಗ SOS ಪಾಪ್-ಅಪ್‌ಗಳು ಆನ್ ಆಗಿವೆ.',
      'turn_on_duty_msg': 'SOS ಪಾಪ್-ಅಪ್‌ಗಳನ್ನು ಪಡೆಯಲು ಕರ್ತವ್ಯ ಆನ್ ಮಾಡಿ.',
      'on_duty_snack': 'ಕರ್ತವ್ಯದಲ್ಲಿ — ನಿಮ್ಮ ಪ್ರದೇಶದಲ್ಲಿ ಘಟನೆಗಳನ್ನು ಮೇಲ್ವಿಚಾರಣೆ ಮಾಡಲಾಗುತ್ತಿದೆ...',
      'off_duty_snack': 'ಸ್ಟ್ಯಾಂಡ್‌ಬೈ — ಕರ್ತವ್ಯ ಅವಧಿ ದಾಖಲಾಗಿದೆ.',
      'leaderboard_offline': 'ಲೀಡರ್‌ಬೋರ್ಡ್ ಆಫ್‌ಲೈನ್',
      'leaderboard_offline_sub': 'ಸಿಂಕ್ ನಿಲ್ಲಿಸಲಾಗಿದೆ. ಕ್ಯಾಶ್ ಸ್ಕೋರ್‌ಗಳು.',
      'set_sos_pin_first': 'ಮೊದಲು SOS ಪಿನ್ ಸೆಟ್ ಮಾಡಿ',
      'set_pin_safety_msg': 'ಸುರಕ್ಷತೆಗಾಗಿ, SOS ರಚಿಸುವ ಮೊದಲು ಪಿನ್ ಸೆಟ್ ಮಾಡಬೇಕು.',
      'set_pin_now': 'ಈಗ ಪಿನ್ ಸೆಟ್ ಮಾಡಿ',
      'later': 'ನಂತರ',
      'sos_are_you_conscious':
          'ನೀವು ಪ್ರಜ್ಞೆಯಲ್ಲಿದ್ದೀರಾ? ದಯವಿಟ್ಟು ಹೌದು ಅಥವಾ ಇಲ್ಲ ಎಂದು ಉತ್ತರಿಸಿ.',
      'sos_tts_opening_guidance':
          'ನಿಮ್ಮ SOS ಸಕ್ರಿಯವಾಗಿದೆ. ಸಹಾಯ ಬರುತ್ತಿದೆ. ಮಾತಿನ ಸೂಚನೆಗಳನ್ನು ಅನುಸರಿಸಿ ಮತ್ತು ಉತ್ತರಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ.',
      'sos_interview_q1_prompt': 'ಏನಾಗುತ್ತಿದೆ? (ತುರ್ತು ಪ್ರಕಾರ)',
      'sos_interview_q2_prompt': 'ನೀವು ಸುರಕ್ಷಿತರೇ? ಎಷ್ಟು ಗಂಭೀರ?',
      'sos_interview_q3_prompt': 'ಎಷ್ಟು ಜನರು ಒಳಗೊಂಡಿದ್ದಾರೆ?',
      'sos_chip_cat_accident': 'ಅಪಘಾತ',
      'sos_chip_cat_medical': 'ವೈದ್ಯಕೀಯ',
      'sos_chip_cat_hazard': 'ಅಪಾಯ (ಬೆಂಕಿ, ಮುಳುಗುವಿಕೆ ಇತ್ಯಾದಿ)',
      'sos_chip_cat_assault': 'ದಾಳಿ',
      'sos_chip_cat_other': 'ಇತರ',
      'sos_chip_safe_critical': 'ಗಂಭೀರ (ಜೀವಕ್ಕೆ ಅಪಾಯ)',
      'sos_chip_safe_injured': 'ಗಾಯ, ಸ್ಥಿರ',
      'sos_chip_safe_danger': 'ಗಾಯವಿಲ್ಲ; ಆದರೆ ಅಪಾಯದಲ್ಲಿ',
      'sos_chip_safe_safe_now': 'ಈಗ ಸುರಕ್ಷಿತ',
      'sos_chip_people_me': 'ನಾನು ಮಾತ್ರ',
      'sos_chip_people_two': 'ಇಬ್ಬರು',
      'sos_chip_people_many': 'ಇಬ್ಬರಿಗಿಂತ ಹೆಚ್ಚು',
      'sos_tts_interview_saved':
          'ಬಾಧಿತ ಸಂದರ್ಶನ ಡೇಟಾ ಉಳಿಸಲಾಗಿದೆ. ಪ್ರತಿಕ್ರಿಯಿಸುವವರಿಗೆ ವಿವರಗಳಿವೆ. ಪ್ರತಿ 60 ಸೆಕೆಂಡುಗಳಿಗೆ ಪ್ರಜ್ಞೆ ಪರಿಶೀಲನೆ ಮುಂದುವರಿಯುತ್ತದೆ.',
      'sos_tts_map_routes':
          'ನಕ್ಷೆ ಟ್ಯಾಬ್ ತೆರೆಯಿರಿ: ಕೆಂಪು ನಿಯೋಜಿತ ಆಸ್ಪತ್ರೆಗೆ ರಸ್ತೆ ಮಾರ್ಗ ಅಥವಾ ಹತ್ತಿರದ ಮಾರ್ಗ; ಹಸಿರು ಸ್ವಯಂಸೇವಕ ಮಾರ್ಗ. ತುರ್ತು ಧ್ವನಿ ಚಾನೆಲ್‌ನಲ್ಲಿ ಇರಿ.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'ಉತ್ತರವಿಲ್ಲ. ಪ್ರಜ್ಞೆ ಪರಿಶೀಲನೆ {max}ರಲ್ಲಿ {n}. ಒಂದು ನಿಮಿಷದಲ್ಲಿ ಮತ್ತೆ ಕೇಳುತ್ತೇವೆ.',
      'volunteer_victim_medical_card': 'ಬಾಧಿತ ವೈದ್ಯಕೀಯ ಕಾರ್ಡ್',
      'volunteer_dispatch_milestone_title': 'ಡಿಸ್ಪ್ಯಾಚ್ ನವೀಕರಣಗಳು',
      'volunteer_dispatch_milestone_hospital': 'ಆಸ್ಪತ್ರೆ ಸ್ವೀಕರಿಸಿದೆ: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ಆಂಬುಲೆನ್ಸ್ ಘಟಕ: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ಆಂಬುಲೆನ್ಸ್ ತಂಡ: ಸಮನ್ವಯ…',
      'volunteer_dispatch_milestone_en_route': 'ಆಂಬುಲೆನ್ಸ್ ಮಾರ್ಗದಲ್ಲಿ',
      'volunteer_triage_qr_report_title': 'QR ಅಥವಾ ಟ್ಯಾಪ್ ವರದಿ',
      'volunteer_triage_qr_report_subtitle':
          'ಹ್ಯಾಂಡ್‌ಆಫ್‌ಗಾಗಿ ಕೋಡ್ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ ಅಥವಾ ಘಟನೆಯ ವರದಿಯನ್ನು ಉಳಿಸಲು ಟ್ಯಾಪ್ ಮಾಡಿ.',
      'volunteer_triage_show_qr': 'QR ತೋರಿಸಿ',
      'volunteer_triage_tap_report': 'ವರದಿ',
      'volunteer_triage_qr_title': 'ಘಟನೆ ಹ್ಯಾಂಡ್‌ಆಫ್ QR',
      'volunteer_triage_qr_body': 'ರಚನಾತ್ಮಕ ಡೇಟಾಗಾಗಿ ಸಿಬ್ಬಂದಿ ಅಥವಾ EMS ಜೊತೆ ಹಂಚಿಕೊಳ್ಳಿ.',
      'volunteer_triage_report_saved': 'ವರದಿ ಈ ಘಟನೆಯ ಅಡಿಯಲ್ಲಿ ಉಳಿಸಲಾಗಿದೆ.',
      'volunteer_triage_report_failed': 'ವರದಿಯನ್ನು ಉಳಿಸಲು ಸಾಧ್ಯವಾಗಲಿಲ್ಲ: ',
      'volunteer_victim_medical_offline_hint': 'SOS ಪ್ಯಾಕೆಟ್‌ನಿಂದ — ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕ್ಯಾಶ್‌ನಿಂದ.',
      'volunteer_victim_consciousness_title': 'ಪ್ರಜ್ಞೆ',
      'volunteer_victim_three_questions': 'ಆರಂಭಿಕ ಉತ್ತರಗಳು',
      'volunteer_major_updates_log': 'ಪ್ರಮುಖ ನವೀಕರಣಗಳು ಮಾತ್ರ',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ಟಿಯರ್ {tier} ಗೆ ಏರಿಸುತ್ತಿದ್ದೇವೆ. ಆಸ್ಪತ್ರೆ {hospital} ಪ್ರಯತ್ನಿಸುತ್ತಿದ್ದೇವೆ.',
      'volunteer_dispatch_trying_hospital': 'ಆಸ್ಪತ್ರೆ {hospital} ಪ್ರಯತ್ನಿಸುತ್ತಿದ್ದೇವೆ.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} ತುರ್ತನ್ನು ಸ್ವೀಕರಿಸಿದೆ. ಆಂಬುಲೆನ್ಸ್ ಸಮನ್ವಯ ನಡೆಯುತ್ತಿದೆ.',
      'volunteer_dispatch_all_hospitals_notified':
          'ಎಲ್ಲಾ ಆಸ್ಪತ್ರೆಗಳಿಗೆ ತಿಳಿಸಲಾಗಿದೆ. ತುರ್ತು ಸೇವೆಗಳಿಗೆ ಮುಂದಕ್ಕೆ ಕಳುಹಿಸುತ್ತಿದ್ದೇವೆ.',
      'sos_dispatch_alerting_nearest_trying':
          'ನಿಮ್ಮ ಪ್ರದೇಶದ ಹತ್ತಿರದ ಆಸ್ಪತ್ರೆಗೆ ಎಚ್ಚರಿಕೆ. {hospital} ಪ್ರಯತ್ನಿಸುತ್ತಿದ್ದೇವೆ.',
      'sos_dispatch_escalating_tier_trying':
          'ಪ್ರತಿಕ್ರಿಯೆ ಇಲ್ಲ. ಟಿಯರ್ {tier} ಗೆ ಏರಿಸುತ್ತಿದ್ದೇವೆ. {hospital} ಪ್ರಯತ್ನಿಸುತ್ತಿದ್ದೇವೆ.',
      'sos_dispatch_retry_previous_trying':
          'ಹಿಂದಿನ ಆಸ್ಪತ್ರೆಯಿಂದ ಪ್ರತಿಕ್ರಿಯೆ ಇಲ್ಲ. {hospital} ಪ್ರಯತ್ನಿಸುತ್ತಿದ್ದೇವೆ.',
      'sos_dispatch_all_hospitals_call_112':
          'ಎಲ್ಲಾ ಆಸ್ಪತ್ರೆಗಳಿಗೆ ತಿಳಿಸಲಾಗಿದೆ. ತುರ್ತು ಸೇವೆಗಳಿಗೆ ದಯವಿಟ್ಟು 112 ಗೆ ಕರೆ ಮಾಡಿ.',
    },

    // ── Malayalam (മലയാളം) ─────────────────────────────────────────────────
    'ml': {
      'app_name': 'EmergencyOS',
      'profile_title': 'പ്രൊഫൈൽ & മെഡിക്കൽ ഐഡി',
      'language': 'ഭാഷ',
      'save_medical_profile': 'മെഡിക്കൽ പ്രൊഫൈൽ സേവ് ചെയ്യുക',
      'critical_medical_info': 'നിർണായക മെഡിക്കൽ വിവരങ്ങൾ',
      'emergency_contacts': 'അടിയന്തര ബന്ധങ്ങൾ',
      'golden_hour_details': 'ഗോൾഡൻ അവർ വിശദാംശങ്ങൾ',
      'sos_lock': 'SOS ലോക്ക്',
      'top_life_savers': 'മികച്ച ജീവൻ രക്ഷകർ',
      'lives_saved': 'രക്ഷിച്ച ജീവനുകൾ',
      'active_alerts': 'സജീവ അലേർട്ടുകൾ',
      'rank': 'റാങ്ക്',
      'on_duty': 'ഡ്യൂട്ടിയിൽ',
      'standby': 'സ്റ്റാൻഡ്ബൈ',
      'sos': 'SOS',
      'call_now': 'ഇപ്പോൾ വിളിക്കുക',
      'quick_guide': 'ദ്രുത ഗൈഡ്',
      'detailed_instructions': 'വിശദമായ നിർദ്ദേശങ്ങൾ',
      'red_flags': 'അപകട സൂചനകൾ',
      'cautions': 'മുന്നറിയിപ്പുകൾ',
      'voice_walkthrough': 'വോയ്‌സ് വഴികാട്ടി',
      'playing': 'പ്ലേ ചെയ്യുന്നു...',
      'swipe_next_guide': 'അടുത്ത ഗൈഡിലേക്ക് സ്വൈപ്പ് ചെയ്യുക',
      'watch_video_guide': 'പൂർണ വീഡിയോ ഗൈഡ് കാണുക',
      'emergency_grid_scan': 'അടിയന്തര ഗ്രിഡ് സ്കാൻ',
      'area_telemetry': 'ഏരിയ ടെലിമെട്രി & അപകട സൂചിക',
      'report_hazard': 'അപകടം റിപ്പോർട്ട് ചെയ്യുക',
      'todays_duty': 'ഇന്നത്തെ ഡ്യൂട്ടി',
      'blood_type': 'രക്ത ഗ്രൂപ്പ്',
      'allergies': 'അലർജികൾ',
      'medical_conditions': 'മെഡിക്കൽ അവസ്ഥകൾ',
      'contact_name': 'പ്രാഥമിക ബന്ധപ്പെടേണ്ട പേര്',
      'contact_phone': 'പ്രാഥമിക ബന്ധപ്പെടേണ്ട ഫോൺ',
      'relationship': 'ബന്ധം',
      'medications': 'നിലവിലെ മരുന്നുകൾ',
      'organ_donor': 'അവയവ ദാന നില',
      'good_morning': 'സുപ്രഭാതം,',
      'good_afternoon': 'ശുഭ ഉച്ചയ്ക്ക്,',
      'good_evening': 'ശുഭ സന്ധ്യ,',
      'hospitals': 'ആശുപത്രികൾ',
      'visual_walkthrough': 'വിഷ്വൽ വഴികാട്ടി',
      'lifeline': 'ലൈഫ്‌ലൈൻ',
      'nav_home': 'ഹോം',
      'nav_map': 'മാപ്പ്',
      'nav_grid': 'ഗ്രിഡ്',
      'nav_profile': 'പ്രൊഫൈൽ',
      'map_caching_offline_pct': 'ഓഫ്‌ലൈനായി പ്രദേശം കാഷ് ചെയ്യുന്നു — {pct}%',
      'map_drill_practice_banner':
          'പരിശീലന ഗ്രിഡ്: പൾസിംഗ് പിൻ = ഡെമോ സജീവ അലേർട്ടുകൾ. ലെയറുകൾക്ക് മാപ്പ് ഫിൽട്ടറുകൾ — യഥാർത്ഥ ഡാറ്റ അല്ല.',
      'map_recenter_tooltip': 'വീണ്ടും കേന്ദ്രീകരിക്കുക',
      'map_legend_hospital': 'ആശുപത്രി',
      'map_legend_live_sos_history': 'ലൈവ് SOS / ചരിത്രം',
      'map_legend_past_this_hex': 'കഴിഞ്ഞ (ഈ ഹെക്സ്)',
      'map_legend_in_area': 'പ്രദേശത്ത് {n}',
      'map_legend_in_cell': 'സെല്ലിൽ {n}',
      'map_legend_volunteers_on_duty': 'ഡ്യൂട്ടിയിലെ സ്വയംസേവകർ',
      'map_legend_volunteers_in_grid': 'ഗ്രിഡിൽ {n}',
      'map_legend_responder_scene': 'പ്രതികരണക്കാരൻ → ദൃശ്യം',
      'map_responder_routes_one': '{n} പാത',
      'map_responder_routes_many': '{n} പാതകൾ',
      'map_filters_title': 'മാപ്പ് ഫിൽട്ടറുകൾ',
      'step_prefix': 'ഘട്ടം',
      'highlights_steps': 'ഓരോന്നായി ഘട്ടങ്ങൾ കാണിക്കുന്നു',
      'offline_mode': 'ഓഫ്‌ലൈൻ — നെറ്റ്‌വർക്ക് വിച്ഛേദിച്ചു',
      'volunteer': 'സന്നദ്ധ പ്രവർത്തകൻ',
      'unranked': 'റാങ്ക് ഇല്ല',
      'live': 'ലൈവ്',
      'you': 'നിങ്ങൾ',
      'saved': 'രക്ഷിച്ചു',
      'xp_responses': 'XP · {0} പ്രതികരണങ്ങൾ',
      'duty_monitoring': 'നിങ്ങൾ ഡ്യൂട്ടിയിൽ ആയിരിക്കുമ്പോൾ SOS പോപ്പ്-അപ്പുകൾ ഓണാണ്.',
      'turn_on_duty_msg': 'SOS പോപ്പ്-അപ്പുകൾ ലഭിക്കാൻ ഡ്യൂട്ടി ഓണാക്കുക.',
      'on_duty_snack': 'ഡ്യൂട്ടിയിൽ — നിങ്ങളുടെ പ്രദേശത്ത് സംഭവങ്ങൾ നിരീക്ഷിക്കുന്നു...',
      'off_duty_snack': 'സ്റ്റാൻഡ്ബൈ — ഡ്യൂട്ടി സെഷൻ രേഖപ്പെടുത്തി.',
      'leaderboard_offline': 'ലീഡർബോർഡ് ഓഫ്‌ലൈൻ',
      'leaderboard_offline_sub': 'സിങ്ക് നിർത്തി. കാഷ് സ്കോറുകൾ.',
      'set_sos_pin_first': 'ആദ്യം SOS പിൻ സെറ്റ് ചെയ്യുക',
      'set_pin_safety_msg': 'സുരക്ഷയ്ക്കായി, SOS സൃഷ്ടിക്കുന്നതിന് മുമ്പ് പിൻ സെറ്റ് ചെയ്യണം.',
      'set_pin_now': 'ഇപ്പോൾ പിൻ സെറ്റ് ചെയ്യുക',
      'later': 'പിന്നീട്',
      'sos_are_you_conscious':
          'നിങ്ങൾ ബോധമുണ്ടോ? ദയവായി അതെ അല്ലെങ്കിൽ ഇല്ല എന്ന് മറുപടി പറയുക.',
      'sos_tts_opening_guidance':
          'നിങ്ങളുടെ SOS സജീവമാണ്. സഹായം വരുന്നു. സംസാര നിർദ്ദേശങ്ങൾ പാലിച്ച് മറുപടി നൽകാൻ ടാപ്പ് ചെയ്യുക.',
      'sos_interview_q1_prompt': 'എന്താണ് സംഭവിക്കുന്നത്? (അടിയന്തര തരം)',
      'sos_interview_q2_prompt': 'നിങ്ങൾ സുരക്ഷിതരാണോ? എത്ര ഗുരുതരം?',
      'sos_interview_q3_prompt': 'എത്ര പേർ ഉൾപ്പെട്ടിരിക്കുന്നു?',
      'sos_chip_cat_accident': 'അപകടം',
      'sos_chip_cat_medical': 'വൈദ്യം',
      'sos_chip_cat_hazard': 'അപായം (തീ, മുങ്ങൽ മുതലായവ)',
      'sos_chip_cat_assault': 'ആക്രമണം',
      'sos_chip_cat_other': 'മറ്റുള്ളവ',
      'sos_chip_safe_critical': 'ഗുരുതരം (ജീവന് ഭീഷണി)',
      'sos_chip_safe_injured': 'പരിക്ക്; സ്ഥിരം',
      'sos_chip_safe_danger': 'പരിക്കില്ല; അപായത്തിൽ',
      'sos_chip_safe_safe_now': 'ഇപ്പോൾ സുരക്ഷിതം',
      'sos_chip_people_me': 'ഞാൻ മാത്രം',
      'sos_chip_people_two': 'ഇരുവർ',
      'sos_chip_people_many': 'ഇരുവരിൽ കൂടുതൽ',
      'sos_tts_interview_saved':
          'ബാധിത ഇന്റർവ്യൂ ഡാറ്റ സേവ് ചെയ്തു. പ്രതികരിക്കുന്നവർക്ക് വിശദാംശങ്ങൾ ഉണ്ട്.',
      'sos_tts_map_routes':
          'മാപ്പ് ടാബ് തുറക്കുക: ചുവപ്പ് നിയോഗിച്ച ആശുപത്രിയിലേക്ക് റോഡ് മാർഗ്ഗം അല്ലെങ്കിൽ സമീപ മാർഗ്ഗം; പച്ച സ്വയംസേവക മാർഗ്ഗം. അടിയന്തര വോയ്സ് ചാനലിൽ തുടരുക.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'മറുപടിയില്ല. ബോധ പരിശോധന {max}ൽ {n}. ഒരു മിനിറ്റിന് ശേഷം വീണ്ടും ചോദിക്കും.',
      'volunteer_victim_medical_card': 'ബാധിത മെഡിക്കൽ കാർഡ്',
      'volunteer_dispatch_milestone_title': 'ഡിസ്പാച്ച് അപ്‌ഡേറ്റുകൾ',
      'volunteer_dispatch_milestone_hospital': 'ആശുപത്രി സ്വീകരിച്ചു: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ആംബുലൻസ് യൂണിറ്റ്: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ആംബുലൻസ് ക്രൂ: ഏകോപനം…',
      'volunteer_dispatch_milestone_en_route': 'ആംബുലൻസ് വഴിയിൽ',
      'volunteer_triage_qr_report_title': 'QR അല്ലെങ്കിൽ ടാപ്പ് റിപ്പോർട്ട്',
      'volunteer_triage_qr_report_subtitle':
          'ഹാൻഡ്‌ഓഫിനായി കോഡ് സ്കാൻ ചെയ്യുക അല്ലെങ്കിൽ സംഭവ റിപ്പോർട്ട് സേവ് ചെയ്യാൻ ടാപ്പ് ചെയ്യുക.',
      'volunteer_triage_show_qr': 'QR കാണിക്കുക',
      'volunteer_triage_tap_report': 'റിപ്പോർട്ട്',
      'volunteer_triage_qr_title': 'സംഭവ ഹാൻഡ്‌ഓഫ് QR',
      'volunteer_triage_qr_body': 'ഘടനാപരമായ ഡാറ്റിനായി സ്റ്റാഫ് അല്ലെങ്കിൽ EMS ഉടൻ പങ്കിടുക.',
      'volunteer_triage_report_saved': 'റിപ്പോർട്ട് ഈ സംഭവത്തിന് കീഴിൽ സേവ് ചെയ്തു.',
      'volunteer_triage_report_failed': 'റിപ്പോർട്ട് സേവ് ചെയ്യാൻ കഴിഞ്ഞില്ല: ',
      'volunteer_victim_medical_offline_hint': 'SOS പാക്കറ്റിൽ നിന്ന് — ഓഫ്‌ലൈനിൽ കാഷിൽ.',
      'volunteer_victim_consciousness_title': 'ബോധം',
      'volunteer_victim_three_questions': 'ആദ്യ മറുപടികൾ',
      'volunteer_major_updates_log': 'പ്രധാന അപ്‌ഡേറ്റുകൾ മാത്രം',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ടിയർ {tier} വരെ ഉയർത്തുന്നു. ആശുപത്രി {hospital} ശ്രമിക്കുന്നു.',
      'volunteer_dispatch_trying_hospital': 'ആശുപത്രി {hospital} ശ്രമിക്കുന്നു.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} അടിയന്തരം സ്വീകരിച്ചു. ആംബുലൻസ് ഏകോപനം നടക്കുന്നു.',
      'volunteer_dispatch_all_hospitals_notified':
          'എല്ലാ ആശുപത്രികളെയും അറിയിച്ചു. അടിയന്തര സേവനങ്ങളിലേക്ക് ഉയർത്തുന്നു.',
      'sos_dispatch_alerting_nearest_trying':
          'നിങ്ങളുടെ പ്രദേശത്തെ അടുത്തുള്ള ആശുപത്രിയെ അലേർട്ട് ചെയ്യുന്നു. {hospital} ശ്രമിക്കുന്നു.',
      'sos_dispatch_escalating_tier_trying':
          'പ്രതികരണമില്ല. ടിയർ {tier} വരെ ഉയർത്തുന്നു. {hospital} ശ്രമിക്കുന്നു.',
      'sos_dispatch_retry_previous_trying':
          'മുമ്പത്തെ ആശുപത്രിയിൽ നിന്ന് പ്രതികരണമില്ല. {hospital} ശ്രമിക്കുന്നു.',
      'sos_dispatch_all_hospitals_call_112':
          'എല്ലാ ആശുപത്രികളെയും അറിയിച്ചു. അടിയന്തര സേവനങ്ങൾക്ക് ദയവായി 112 വിളിക്കുക.',
    },

    // ── Bengali (বাংলা) ────────────────────────────────────────────────────
    'bn': {
      'app_name': 'EmergencyOS',
      'profile_title': 'প্রোফাইল ও মেডিক্যাল আইডি',
      'language': 'ভাষা',
      'save_medical_profile': 'মেডিক্যাল প্রোফাইল সংরক্ষণ করুন',
      'critical_medical_info': 'গুরুত্বপূর্ণ চিকিৎসা তথ্য',
      'emergency_contacts': 'জরুরি যোগাযোগ',
      'golden_hour_details': 'গোল্ডেন আওয়ার বিবরণ',
      'sos_lock': 'SOS লক',
      'top_life_savers': 'শীর্ষ জীবন রক্ষাকারী',
      'lives_saved': 'উদ্ধারকৃত প্রাণ',
      'active_alerts': 'সক্রিয় সতর্কতা',
      'rank': 'র‍্যাঙ্ক',
      'on_duty': 'ডিউটিতে',
      'standby': 'স্ট্যান্ডবাই',
      'sos': 'SOS',
      'call_now': 'এখনই কল করুন',
      'quick_guide': 'দ্রুত গাইড',
      'detailed_instructions': 'বিস্তারিত নির্দেশনা',
      'red_flags': 'বিপদ সংকেত',
      'cautions': 'সতর্কতা',
      'voice_walkthrough': 'ভয়েস গাইড',
      'playing': 'চলছে...',
      'swipe_next_guide': 'পরবর্তী গাইডের জন্য সোয়াইপ করুন',
      'watch_video_guide': 'সম্পূর্ণ ভিডিও গাইড দেখুন',
      'emergency_grid_scan': 'জরুরি গ্রিড স্ক্যান',
      'area_telemetry': 'এলাকা টেলিমেট্রি ও ঝুঁকি সূচক',
      'report_hazard': 'বিপদ রিপোর্ট করুন',
      'todays_duty': 'আজকের দায়িত্ব',
      'blood_type': 'রক্তের গ্রুপ',
      'allergies': 'অ্যালার্জি',
      'medical_conditions': 'চিকিৎসা অবস্থা',
      'contact_name': 'প্রাথমিক যোগাযোগের নাম',
      'contact_phone': 'প্রাথমিক যোগাযোগ ফোন',
      'relationship': 'সম্পর্ক',
      'medications': 'বর্তমান ওষুধ',
      'organ_donor': 'অঙ্গ দাতা স্থিতি',
      'good_morning': 'সুপ্রভাত,',
      'good_afternoon': 'শুভ অপরাহ্ন,',
      'good_evening': 'শুভ সন্ধ্যা,',
      'hospitals': 'হাসপাতাল',
      'visual_walkthrough': 'ভিজ্যুয়াল গাইড',
      'lifeline': 'লাইফলাইন',
      'nav_home': 'হোম',
      'nav_map': 'ম্যাপ',
      'nav_grid': 'গ্রিড',
      'nav_profile': 'প্রোফাইল',
      'map_caching_offline_pct': 'অফলাইনের জন্য এলাকা ক্যাশ হচ্ছে — {pct}%',
      'map_drill_practice_banner':
          'অনুশীলন গ্রিড: পালসিং পিন = ডেমো সক্রিয় সতর্কতা। স্তরের জন্য মানচিত্র ফিল্টার — আসল ডেটা নয়।',
      'map_recenter_tooltip': 'আবার কেন্দ্রে আনুন',
      'map_legend_hospital': 'হাসপাতাল',
      'map_legend_live_sos_history': 'লাইভ SOS / ইতিহাস',
      'map_legend_past_this_hex': 'অতীত (এই হেক্স)',
      'map_legend_in_area': 'এলাকায় {n}',
      'map_legend_in_cell': 'সেলে {n}',
      'map_legend_volunteers_on_duty': 'ডিউটিতে স্বেচ্ছাসেবক',
      'map_legend_volunteers_in_grid': 'গ্রিডে {n}',
      'map_legend_responder_scene': 'প্রতিকারকারী → দৃশ্য',
      'map_responder_routes_one': '{n} রুট',
      'map_responder_routes_many': '{n} রুট',
      'map_filters_title': 'মানচিত্র ফিল্টার',
      'step_prefix': 'ধাপ',
      'highlights_steps': 'একটি একটি করে ধাপ দেখায়',
      'offline_mode': 'অফলাইন — নেটওয়ার্ক বিচ্ছিন্ন',
      'volunteer': 'স্বেচ্ছাসেবক',
      'unranked': 'র‍্যাঙ্কবিহীন',
      'live': 'লাইভ',
      'you': 'আপনি',
      'saved': 'বাঁচানো',
      'xp_responses': 'XP · {0} প্রতিক্রিয়া',
      'duty_monitoring': 'আপনি ডিউটিতে থাকাকালীন SOS পপ-আপ চালু আছে।',
      'turn_on_duty_msg': 'SOS পপ-আপ পেতে ডিউটি চালু করুন।',
      'on_duty_snack': 'ডিউটিতে — আপনার এলাকায় ঘটনা পর্যবেক্ষণ করা হচ্ছে...',
      'off_duty_snack': 'স্ট্যান্ডবাই — ডিউটি সেশন রেকর্ড হয়েছে।',
      'leaderboard_offline': 'লিডারবোর্ড অফলাইন',
      'leaderboard_offline_sub': 'সিংক বিরত। ক্যাশ স্কোর দেখানো হচ্ছে।',
      'set_sos_pin_first': 'প্রথমে SOS পিন সেট করুন',
      'set_pin_safety_msg': 'নিরাপত্তার জন্য, SOS তৈরি করার আগে পিন সেট করতে হবে।',
      'set_pin_now': 'এখনই পিন সেট করুন',
      'later': 'পরে',
      'sos_screen_title': 'SOS',
      'sos_hold_banner': 'পাঠাতে ৩ সেকেন্ড ধরে চেপে ধরুন।',
      'sos_hold_button': 'SOS পাঠাতে চেপে ধরুন',
      'sos_semantics_hold_hint': 'SOS। পাঠাতে তিন সেকেন্ড চেপে ধরুন।',
      'home_duty_heading': 'আজকের দায়িত্ব',
      'home_duty_progress': '{done}/{total} সম্পন্ন',
      'home_map_semantics': 'আপনার এলাকা ও অবস্থান দেখানো মানচিত্র',
      'home_recenter_map': 'মানচিত্র আপনার অবস্থানে কেন্দ্র করুন',
      'home_sos_large_fab_hint': 'জরুরি সতর্কতার জন্য SOS কাউন্টডাউন খুলুন',
      'home_sos_cancelled_snack': 'SOS বাতিল।',
      'home_sos_sent_snack': 'SOS পাঠানো হয়েছে! জরুরি সেবা অবহিত।',
      'quick_sos_title': 'দ্রুত SOS',
      'quick_sos_subtitle': 'উত্তর দিন — বিবরণ দিলে সাহায্য দ্রুত আসে',
      'quick_sos_practice_banner':
          'অনুশীলন গাইডেড ইনটেক — জমা দিলে আসল SOS হবে না।',
      'quick_sos_section_what': 'জরুরি কী?',
      'quick_sos_section_someone_else': 'আপনি কি অন্যের জন্য SOS চালু করছেন?',
      'quick_sos_send_now': 'এখনই SOS পাঠান',
      'quick_sos_select_first': 'জরুরি নির্বাচন করুন ও নিশ্চিত করুন',
      'quick_sos_section_victim': 'কর্তৃগত অবস্থা',
      'quick_sos_victim_subtitle': 'উদ্ধারকারীদের সঠিক সরঞ্জাম প্রস্তুত করতে সাহায্য করে',
      'quick_sos_section_people': 'কতজনের সাহায্য দরকার?',
      'quick_sos_yes_someone_else': 'হ্যাঁ — অন্যের জন্য',
      'quick_sos_no_for_me': 'না — আমার জন্য',
      'quick_sos_other_hint': 'সংক্ষেপে আপনার পরিস্থিতি বর্ণনা করুন...',
      'quick_sos_close': 'দ্রুত SOS বন্ধ করুন',
      'quick_sos_drill_submit_disabled':
          'অনুশীলন: জমা নিষ্ক্রিয়। ড্রিলের জন্য হোমে লাল SOS ৩ সে. চেপে ধরুন।',
      'quick_sos_failed': 'SOS ব্যর্থ: {detail}',
      'quick_sos_could_not_start': 'SOS শুরু করা যায়নি। আবার চেষ্টা করুন।',
      'quick_sos_victim_conscious_q': 'ব্যক্তি সচেতন?',
      'sos_are_you_conscious':
          'আপনি সচেতন? দয়া করে হ্যাঁ বা না উত্তর দিন।',
      'sos_tts_opening_guidance':
          'আপনার SOS সক্রিয়। সাহায্য আসছে। বলা নির্দেশাবলী অনুসরণ করুন এবং উত্তর দিতে ট্যাপ করুন।',
      'sos_interview_q1_prompt': 'কী হচ্ছে? (জরুরি ধরন)',
      'sos_interview_q2_prompt': 'আপনি কি নিরাপদ? কতটা গুরুতর?',
      'sos_interview_q3_prompt': 'কতজন জড়িত?',
      'sos_chip_cat_accident': 'দুর্ঘটনা',
      'sos_chip_cat_medical': 'চিকিৎসা',
      'sos_chip_cat_hazard': 'বিপদ (আগুন, ডুবি ইত্যাদি)',
      'sos_chip_cat_assault': 'আক্রমণ',
      'sos_chip_cat_other': 'অন্যান্য',
      'sos_chip_safe_critical': 'গুরুতর (জীবনঘাতী)',
      'sos_chip_safe_injured': 'আহত কিন্তু স্থিতিশীল',
      'sos_chip_safe_danger': 'আহত নয় কিন্তু বিপদে',
      'sos_chip_safe_safe_now': 'এখন নিরাপদ',
      'sos_chip_people_me': 'শুধু আমি',
      'sos_chip_people_two': 'দুজন',
      'sos_chip_people_many': 'দুজনের বেশি',
      'sos_tts_interview_saved':
          'সব ভুক্তভোগী সাক্ষাৎকার ডেটা সংরক্ষিত। উদ্ধারকারীদের বিস্তারিত আছে।',
      'sos_tts_map_routes':
          'মানচিত্র ট্যাব খুলুন: লাল নির্ধারিত হাসপাতালের রাস্তার পথ, নাহলে সংক্ষিপ্ত পথ; সবুজ স্বেচ্ছাসেবক পথ। জরুরি ভয়েস চ্যানেলে থাকুন।',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'উত্তর নেই। সচেতনতা পরীক্ষা {max} এর {n}। এক মিনিট পর আবার জিজ্ঞাসা করব।',
      'volunteer_victim_medical_card': 'ভুক্তভোগী মেডিকেল কার্ড',
      'volunteer_dispatch_milestone_title': 'ডিসপ্যাচ আপডেট',
      'volunteer_dispatch_milestone_hospital': 'হাসপাতাল গ্রহণ: {hospital}',
      'volunteer_dispatch_milestone_unit': 'অ্যাম্বুলেন্স ইউনিট: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'অ্যাম্বুলেন্স ক্রু: সমন্বয়…',
      'volunteer_dispatch_milestone_en_route': 'অ্যাম্বুলেন্স পথে',
      'volunteer_triage_qr_report_title': 'QR বা ট্যাপ রিপোর্ট',
      'volunteer_triage_qr_report_subtitle':
          'হ্যান্ডঅফের জন্য কোড স্ক্যান করুন বা ঘটনার রিপোর্ট সেভ করতে ট্যাপ করুন।',
      'volunteer_triage_show_qr': 'QR দেখান',
      'volunteer_triage_tap_report': 'রিপোর্ট',
      'volunteer_triage_qr_title': 'ঘটনা হ্যান্ডঅফ QR',
      'volunteer_triage_qr_body': 'কাঠামোগত ডেটার জন্য স্টাফ বা EMS-এর সাথে শেয়ার করুন।',
      'volunteer_triage_report_saved': 'রিপোর্ট এই ঘটনার অধীনে সংরক্ষিত।',
      'volunteer_triage_report_failed': 'রিপোর্ট সংরক্ষণ ব্যর্থ: ',
      'volunteer_victim_medical_offline_hint': 'SOS প্যাকেট থেকে — অফলাইনে ক্যাশে।',
      'volunteer_victim_consciousness_title': 'সচেতনতা',
      'volunteer_victim_three_questions': 'প্রাথমিক উত্তর',
      'volunteer_major_updates_log': 'শুধু গুরুত্বপূর্ণ আপডেট',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'টিয়ার {tier} এ উন্নীত করছি। হাসপাতাল {hospital} চেষ্টা করছি।',
      'volunteer_dispatch_trying_hospital': 'হাসপাতাল {hospital} চেষ্টা করছি।',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} জরুরি গ্রহণ করেছে। অ্যাম্বুলেন্স সমন্বয় চলছে।',
      'volunteer_dispatch_all_hospitals_notified':
          'সব হাসপাতালকে জানানো হয়েছে। জরুরি সেবায় এসকেলেট করছি।',
      'sos_dispatch_alerting_nearest_trying':
          'আপনার এলাকার নিকটতম হাসপাতালে সতর্ক করছি। {hospital} চেষ্টা করছি।',
      'sos_dispatch_escalating_tier_trying':
          'কোনো সাড়া নেই। টিয়ার {tier} এ উন্নীত করছি। {hospital} চেষ্টা করছি।',
      'sos_dispatch_retry_previous_trying':
          'আগের হাসপাতাল থেকে সাড়া নেই। {hospital} চেষ্টা করছি।',
      'sos_dispatch_all_hospitals_call_112':
          'সব হাসপাতালকে জানানো হয়েছে। জরুরি সেবার জন্য ১১২ কল করুন।',
      'quick_sos_victim_breathing_q': 'ব্যক্তি শ্বাস নিচ্ছে?',
      'quick_sos_label_yes': 'হ্যাঁ',
      'quick_sos_label_no': 'না',
      'quick_sos_label_unsure': 'নিশ্চিত নয়',
      'quick_sos_person': 'ব্যক্তি',
      'quick_sos_people': 'ব্যক্তি',
      'quick_sos_people_three_plus': '৩+',
      'login_tagline': 'প্রাণ বাঁচাই',
      'login_subtitle':
          'জরুরি রিপোর্ট করুন, স্বেচ্ছাসেবকদের সঙ্গে সমন্বয় করুন, গোল্ডেন আওয়ারে প্রাণ বাঁচান।',
      'login_continue_google': 'Google দিয়ে চালিয়ে যান',
      'login_continue_phone': 'ফোন দিয়ে চালিয়ে যান',
      'login_send_code': 'যাচাইকরণ কোড পাঠান',
      'login_verify_login': 'যাচাই করে লগ ইন',
      'login_phone_label': 'ফোন নম্বর',
      'login_phone_hint': '+8801XXXXXXXXX',
      'login_otp_label': 'যাচাইকরণ কোড (OTP)',
      'login_back_options': 'বিকল্পে ফিরুন',
      'login_change_phone': 'ফোন নম্বর পরিবর্তন',
      'login_drill_mode': 'ড্রিল মোড',
      'login_drill_subtitle': 'অনুশীলনের জন্য ট্যাপ — আসল SOS নয়',
      'login_drill_semantics': 'ড্রিল মোড, আসল জরুরি ছাড়া অনুশীলন',
      'login_practise_victim': 'কর্তৃগত হিসেবে অনুশীলন',
      'login_practise_volunteer': 'স্বেচ্ছাসেবক হিসেবে অনুশীলন',
      'login_admin_note':
          'মাস্টার কনসোল: আলাদা অ্যাকাউন্ট নেই — নিচে ট্যাপ করুন। লগ ইন না থাকলে হালকা বেনামি সেশন।',
      'login_ems_dashboard': 'EMS ড্যাশবোর্ড',
      'login_emergency_operator': 'জরুরি সেবা অপারেটর লগ ইন',
      'ai_assist_practice_banner':
          'অনুশীলন Lifeline — আসল ডিসপ্যাচে কিছু যায় না।',
      'ai_assist_rail_semantics': 'Lifeline স্তর {n}: {title}',
      'ai_assist_emergency_toggle_on': 'জরুরি মোড চালু, তাৎক্ষণিক গাইড',
      'ai_assist_emergency_toggle_off': 'জরুরি মোড বন্ধ',
      'dashboard_exit_drill_title': 'ড্রিল মোড থেকে বের হবেন?',
      'dashboard_exit_drill_body':
          'আপনি এই অনুশীলন সেশন থেকে সাইন আউট হয়ে লগইনে ফিরবেন।',
      'dashboard_back_login_tooltip': 'লগইনে ফিরুন',
      'dashboard_exit_drill_confirm': 'প্রস্থান',
    },

    // ── Marathi (मराठी) ────────────────────────────────────────────────────
    'mr': {
      'app_name': 'EmergencyOS',
      'profile_title': 'प्रोफाइल आणि वैद्यकीय ओळख',
      'language': 'भाषा',
      'save_medical_profile': 'वैद्यकीय प्रोफाइल जतन करा',
      'critical_medical_info': 'महत्त्वाची वैद्यकीय माहिती',
      'emergency_contacts': 'आपत्कालीन संपर्क',
      'golden_hour_details': 'गोल्डन अवर तपशील',
      'sos_lock': 'SOS लॉक',
      'top_life_savers': 'शीर्ष जीवनरक्षक',
      'lives_saved': 'वाचवलेले जीव',
      'active_alerts': 'सक्रिय सूचना',
      'rank': 'रँक',
      'on_duty': 'ड्युटीवर',
      'standby': 'स्टँडबाय',
      'sos': 'SOS',
      'call_now': 'आत्ता कॉल करा',
      'quick_guide': 'जलद मार्गदर्शक',
      'detailed_instructions': 'तपशीलवार सूचना',
      'red_flags': 'धोक्याचे संकेत',
      'cautions': 'सावधगिरी',
      'voice_walkthrough': 'व्हॉइस मार्गदर्शन',
      'playing': 'प्ले होत आहे...',
      'swipe_next_guide': 'पुढील मार्गदर्शकासाठी स्वाइप करा',
      'watch_video_guide': 'संपूर्ण व्हिडिओ मार्गदर्शक पहा',
      'emergency_grid_scan': 'आपत्कालीन ग्रिड स्कॅन',
      'area_telemetry': 'क्षेत्र टेलिमेट्री आणि जोखीम निर्देशांक',
      'report_hazard': 'धोका नोंदवा',
      'todays_duty': 'आजची ड्युटी',
      'blood_type': 'रक्तगट',
      'allergies': 'ॲलर्जी',
      'medical_conditions': 'वैद्यकीय स्थिती',
      'contact_name': 'प्राथमिक संपर्क नाव',
      'contact_phone': 'प्राथमिक संपर्क फोन',
      'relationship': 'नाते',
      'medications': 'सध्याची औषधे',
      'organ_donor': 'अवयवदान स्थिती',
      'good_morning': 'सुप्रभात,',
      'good_afternoon': 'शुभ दुपार,',
      'good_evening': 'शुभ संध्याकाळ,',
      'hospitals': 'रुग्णालये',
      'visual_walkthrough': 'दृश्य मार्गदर्शन',
      'lifeline': 'लाइफलाइन',
      'nav_home': 'होम',
      'nav_map': 'नकाशा',
      'nav_grid': 'ग्रिड',
      'nav_profile': 'प्रोफाइल',
      'map_caching_offline_pct': 'ऑफलाइनसाठी क्षेत्र कॅश होत आहे — {pct}%',
      'map_drill_practice_banner':
          'सराव ग्रिड: पल्सिंग पिन = डेमो सक्रिय सतर्कता. थरांसाठी नकाशा फिल्टर — खरे डेटा नाही.',
      'map_recenter_tooltip': 'पुन्हा केंद्रित करा',
      'map_legend_hospital': 'रुग्णालय',
      'map_legend_live_sos_history': 'लाइव्ह SOS / इतिहास',
      'map_legend_past_this_hex': 'मागील (हा हेक्स)',
      'map_legend_in_area': 'क्षेत्रात {n}',
      'map_legend_in_cell': 'सेलमध्ये {n}',
      'map_legend_volunteers_on_duty': 'ड्युटीवर स्वयंसेवक',
      'map_legend_volunteers_in_grid': 'ग्रिडमध्ये {n}',
      'map_legend_responder_scene': 'प्रतिसाद देणारा → दृश्य',
      'map_responder_routes_one': '{n} मार्ग',
      'map_responder_routes_many': '{n} मार्ग',
      'map_filters_title': 'नकाशा फिल्टर',
      'step_prefix': 'पायरी',
      'highlights_steps': 'एक एक करून पायऱ्या दाखवतो',
      'offline_mode': 'ऑफलाइन — नेटवर्क डिस्कनेक्ट',
      'volunteer': 'स्वयंसेवक',
      'unranked': 'रँक नाही',
      'live': 'लाइव्ह',
      'you': 'तुम्ही',
      'saved': 'वाचवले',
      'xp_responses': 'XP · {0} प्रतिसाद',
      'duty_monitoring': 'तुम्ही ड्युटीवर असताना SOS पॉप-अप चालू आहेत.',
      'turn_on_duty_msg': 'SOS पॉप-अप मिळवण्यासाठी ड्युटी चालू करा.',
      'on_duty_snack': 'ड्युटीवर — तुमच्या परिसरातील घटनांचे निरीक्षण...',
      'off_duty_snack': 'स्टँडबाय — ड्युटी सत्र नोंदवले.',
      'leaderboard_offline': 'लीडरबोर्ड ऑफलाइन',
      'leaderboard_offline_sub': 'सिंकिंग थांबले. कॅश्ड स्कोर.',
      'set_sos_pin_first': 'प्रथम SOS पिन सेट करा',
      'set_pin_safety_msg': 'सुरक्षिततेसाठी, SOS तयार करण्यापूर्वी पिन सेट करणे आवश्यक आहे.',
      'set_pin_now': 'आत्ता पिन सेट करा',
      'later': 'नंतर',
      'sos_are_you_conscious':
          'तुम्ही होशीत आहात? कृपया होय किंवा नाही उत्तर द्या.',
      'sos_tts_opening_guidance':
          'तुमचे SOS सक्रिय आहे. मदत येत आहे. बोललेले सूचना पाळा आणि उत्तर देण्यास टॅप करा.',
      'sos_interview_q1_prompt': 'काय घडत आहे? (आपत्कालीन प्रकार)',
      'sos_interview_q2_prompt': 'तुम्ही सुरक्षित आहात? किती गंभीर?',
      'sos_interview_q3_prompt': 'किती लोक सामील आहेत?',
      'sos_chip_cat_accident': 'अपघात',
      'sos_chip_cat_medical': 'वैद्यकीय',
      'sos_chip_cat_hazard': 'धोका (आग, बुडणे इ.)',
      'sos_chip_cat_assault': 'हल्ला',
      'sos_chip_cat_other': 'इतर',
      'sos_chip_safe_critical': 'गंभीर (जीवाला धोका)',
      'sos_chip_safe_injured': 'जखमी पण स्थिर',
      'sos_chip_safe_danger': 'जखमी नाही पण धोक्यात',
      'sos_chip_safe_safe_now': 'आता सुरक्षित',
      'sos_chip_people_me': 'फक्त मी',
      'sos_chip_people_two': 'दोघे',
      'sos_chip_people_many': 'दोघांपेक्षा जास्त',
      'sos_tts_interview_saved':
          'सर्व मुलाखत डेटा जतन केला. प्रतिसादकर्त्यांना तपशील आहेत.',
      'sos_tts_map_routes':
          'नकाशा टॅब उघडा: ठोस लाल नियुक्त रुग्णालयाचा रस्ता किंवा जवळचा मार्ग; हिरवा स्वयंसेवक मार्ग. आपत्कालीन आवाज चॅनेलवर रहा.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'उत्तर नाही. होश तपासणी {max} पैकी {n}. एका मिनिटात पुन्हा विचारू.',
      'volunteer_victim_medical_card': 'बाधित वैद्यकीय कार्ड',
      'volunteer_dispatch_milestone_title': 'डिस्पॅच अपडेट',
      'volunteer_dispatch_milestone_hospital': 'रुग्णालय स्वीकारले: {hospital}',
      'volunteer_dispatch_milestone_unit': 'रुग्णवाहिका युनिट: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'रुग्णवाहिका क्रू: समन्वय…',
      'volunteer_dispatch_milestone_en_route': 'रुग्णवाहिका मार्गावर',
      'volunteer_triage_qr_report_title': 'QR किंवा टॅप अहवाल',
      'volunteer_triage_qr_report_subtitle':
          'हँडऑफसाठी कोड स्कॅन करा किंवा घटनेचा अहवाल जतन करण्यासाठी टॅप करा.',
      'volunteer_triage_show_qr': 'QR दाखवा',
      'volunteer_triage_tap_report': 'अहवाल',
      'volunteer_triage_qr_title': 'घटना हँडऑफ QR',
      'volunteer_triage_qr_body': 'संरचित डेटासाठी कर्मचारी किंवा EMS सोबत शेअर करा.',
      'volunteer_triage_report_saved': 'अहवाल या घटनेखाली जतन केला.',
      'volunteer_triage_report_failed': 'अहवाल जतन करता आला नाही: ',
      'volunteer_victim_medical_offline_hint': 'SOS पॅकेटमधून — ऑफलाइन कॅशमधून.',
      'volunteer_victim_consciousness_title': 'होश',
      'volunteer_victim_three_questions': 'सुरुवातीची उत्तरे',
      'volunteer_major_updates_log': 'फक्त मुख्य अपडेट',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'टियर {tier} पर्यंत वाढवत आहोत. रुग्णालय {hospital} प्रयत्न करत आहोत.',
      'volunteer_dispatch_trying_hospital': 'रुग्णालय {hospital} प्रयत्न करत आहोत.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} ने आपत्काल स्वीकारला. रुग्णवाहिका समन्वय सुरू आहे.',
      'volunteer_dispatch_all_hospitals_notified':
          'सर्व रुग्णालयांना कळवले. आपत्कालीन सेवांकडे पाठवत आहोत.',
      'sos_dispatch_alerting_nearest_trying':
          'तुमच्या क्षेत्रातील जवळच्या रुग्णालयाला सूचित करत आहोत. {hospital} प्रयत्न करत आहोत.',
      'sos_dispatch_escalating_tier_trying':
          'प्रतिसाद नाही. टियर {tier} पर्यंत वाढवत आहोत. {hospital} प्रयत्न करत आहोत.',
      'sos_dispatch_retry_previous_trying':
          'मागील रुग्णालयाकडून प्रतिसाद नाही. {hospital} प्रयत्न करत आहोत.',
      'sos_dispatch_all_hospitals_call_112':
          'सर्व रुग्णालयांना कळवले. आपत्कालीन सेवांसाठी कृपया 112 वर कॉल करा.',
    },

    // ── Gujarati (ગુજરાતી) ─────────────────────────────────────────────────
    'gu': {
      'app_name': 'EmergencyOS',
      'profile_title': 'પ્રોફાઇલ અને મેડિકલ આઈડી',
      'language': 'ભાષા',
      'save_medical_profile': 'મેડિકલ પ્રોફાઇલ સાચવો',
      'critical_medical_info': 'મહત્વની તબીબી માહિતી',
      'emergency_contacts': 'કટોકટી સંપર્કો',
      'golden_hour_details': 'ગોલ્ડન અવર વિગતો',
      'sos_lock': 'SOS લોક',
      'top_life_savers': 'ટોચના જીવનરક્ષકો',
      'lives_saved': 'બચાવેલા જીવ',
      'active_alerts': 'સક્રિય ચેતવણીઓ',
      'rank': 'રેન્ક',
      'on_duty': 'ફરજ પર',
      'standby': 'સ્ટેન્ડબાય',
      'sos': 'SOS',
      'call_now': 'હમણાં કૉલ કરો',
      'quick_guide': 'ઝડપી માર્ગદર્શિકા',
      'detailed_instructions': 'વિગતવાર સૂચનાઓ',
      'red_flags': 'જોખમના સંકેતો',
      'cautions': 'સાવચેતીઓ',
      'voice_walkthrough': 'વૉઇસ માર્ગદર્શન',
      'playing': 'ચાલુ છે...',
      'swipe_next_guide': 'આગળની માર્ગદર્શિકા માટે સ્વાઇપ કરો',
      'watch_video_guide': 'સંપૂર્ણ વીડિયો માર્ગદર્શિકા જુઓ',
      'emergency_grid_scan': 'કટોકટી ગ્રિડ સ્કેન',
      'area_telemetry': 'વિસ્તાર ટેલિમેટ્રી અને જોખમ સૂચકાંક',
      'report_hazard': 'જોખમ રિપોર્ટ કરો',
      'todays_duty': 'આજની ફરજ',
      'blood_type': 'લોહીનો પ્રકાર',
      'allergies': 'એલર્જી',
      'medical_conditions': 'તબીબી સ્થિતિ',
      'contact_name': 'પ્રાથમિક સંપર્ક નામ',
      'contact_phone': 'પ્રાથમિક સંપર્ક ફોન',
      'relationship': 'સંબંધ',
      'medications': 'વર્તમાન દવાઓ',
      'organ_donor': 'અંગ દાન સ્થિતિ',
      'good_morning': 'સુપ્રભાત,',
      'good_afternoon': 'શુભ બપોર,',
      'good_evening': 'શુભ સાંજ,',
      'hospitals': 'હોસ્પિટલો',
      'visual_walkthrough': 'દ્રશ્ય માર્ગદર્શન',
      'lifeline': 'લાઇફલાઇન',
      'nav_home': 'હોમ',
      'nav_map': 'નકશો',
      'nav_grid': 'ગ્રિડ',
      'nav_profile': 'પ્રોફાઇલ',
      'map_caching_offline_pct': 'ઑફલાઇન માટે વિસ્તાર કેશ થઈ રહ્યો છે — {pct}%',
      'map_drill_practice_banner':
          'અભ્યાસ ગ્રિડ: પલ્સિંગ પિન = ડેમો સક્રિય અલર્ટ્સ. પરતો માટે નકશા ફિલ્ટર — વાસ્તવિક ડેટા નહીં.',
      'map_recenter_tooltip': 'ફરીથી કેન્દ્રિત કરો',
      'map_legend_hospital': 'હોસ્પિટલ',
      'map_legend_live_sos_history': 'લાઇવ SOS / ઇતિહાસ',
      'map_legend_past_this_hex': 'ગત (આ હેક્સ)',
      'map_legend_in_area': 'વિસ્તારમાં {n}',
      'map_legend_in_cell': 'સેલમાં {n}',
      'map_legend_volunteers_on_duty': 'ડ્યુટી પર સ્વયંસેવકો',
      'map_legend_volunteers_in_grid': 'ગ્રિડમાં {n}',
      'map_legend_responder_scene': 'પ્રતિસાદ આપનાર → દૃશ્ય',
      'map_responder_routes_one': '{n} માર્ગ',
      'map_responder_routes_many': '{n} માર્ગો',
      'map_filters_title': 'નકશા ફિલ્ટર',
      'step_prefix': 'પગલું',
      'highlights_steps': 'એક એક કરીને પગલાં બતાવે છે',
      'offline_mode': 'ઓફલાઇન — નેટવર્ક ડિસ્કનેક્ટ',
      'volunteer': 'સ્વયંસેવક',
      'unranked': 'રેન્ક નથી',
      'live': 'લાઇવ',
      'you': 'તમે',
      'saved': 'બચાવ્યા',
      'xp_responses': 'XP · {0} પ્રતિભાવો',
      'duty_monitoring': 'તમે ફરજ પર હોવ ત્યારે SOS પોપ-અપ ચાલુ છે.',
      'turn_on_duty_msg': 'SOS પોપ-અપ મેળવવા માટે ફરજ ચાલુ કરો.',
      'on_duty_snack': 'ફરજ પર — તમારા વિસ્તારમાં ઘટનાઓનું નિરીક્ષણ...',
      'off_duty_snack': 'સ્ટેન્ડબાય — ફરજ સત્ર રેકોર્ડ થયું.',
      'leaderboard_offline': 'લીડરબોર્ડ ઓફલાઇન',
      'leaderboard_offline_sub': 'સિંક અટકી. કેશ્ડ સ્કોર.',
      'set_sos_pin_first': 'પહેલા SOS પિન સેટ કરો',
      'set_pin_safety_msg': 'સુરક્ષા માટે, SOS બનાવતા પહેલા પિન સેટ કરવો જરૂરી છે.',
      'set_pin_now': 'હમણાં પિન સેટ કરો',
      'later': 'પછી',
      'sos_are_you_conscious':
          'તમે સચેત છો? કૃપા કરીને હા અથવા ના જવાબ આપો.',
      'sos_tts_opening_guidance':
          'તમારું SOS સક્રિય છે. મદદ આવી રહી છે. બોલાતા સૂચનો અનુસરો અને જવાબ આપવા ટૅપ કરો.',
      'sos_interview_q1_prompt': 'શું થઈ રહ્યું છે? (કટોકટી પ્રકાર)',
      'sos_interview_q2_prompt': 'તમે સુરક્ષિત છો? કેટલું ગંભીર?',
      'sos_interview_q3_prompt': 'કેટલા લોકો સામેલ છે?',
      'sos_chip_cat_accident': 'અકસ્માત',
      'sos_chip_cat_medical': 'તબીબી',
      'sos_chip_cat_hazard': 'જોખમ (આગ, ડૂબવું વગેરે)',
      'sos_chip_cat_assault': 'હુમલો',
      'sos_chip_cat_other': 'અન્ય',
      'sos_chip_safe_critical': 'ગંભીર (જીવલેણ)',
      'sos_chip_safe_injured': 'ઇજા પણ સ્થિર',
      'sos_chip_safe_danger': 'ઇજા નહીં પણ જોખમમાં',
      'sos_chip_safe_safe_now': 'હવે સુરક્ષિત',
      'sos_chip_people_me': 'ફક્ત હું',
      'sos_chip_people_two': 'બે',
      'sos_chip_people_many': 'બે કરતાં વધુ',
      'sos_tts_interview_saved':
          'બધો ઇન્ટરવ્યૂ ડેટા સાચવ્યો. પ્રતિસાદકર્તાઓ પાસે વિગતો છે.',
      'sos_tts_map_routes':
          'નકશો ટૅબ ખોલો: લાલ સોંપેલ હોસ્પિટલનો રોડ માર્ગ અથવા નજીકનો માર્ગ; લીલો સ્વયંસેવક માર્ગ. કટોકટી અવાજ ચેનલ પર રહો.',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'જવાબ નહીં. સચેત તપાસ {max} માંથી {n}. એક મિનિટ પછી ફરી પૂછીશું.',
      'volunteer_victim_medical_card': 'પીડિત તબીબી કાર્ડ',
      'volunteer_dispatch_milestone_title': 'ડિસ્પેચ અપડેટ',
      'volunteer_dispatch_milestone_hospital': 'હોસ્પિટલ સ્વીકારી: {hospital}',
      'volunteer_dispatch_milestone_unit': 'એમ્બ્યુલન્સ યુનિટ: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'એમ્બ્યુલન્સ ક્રૂ: સંકલન…',
      'volunteer_dispatch_milestone_en_route': 'એમ્બ્યુલન્સ માર્ગ પર',
      'volunteer_triage_qr_report_title': 'QR અથવા ટૅપ રિપોર્ટ',
      'volunteer_triage_qr_report_subtitle':
          'હેન્ડઓફ માટે કોડ સ્કેન કરો અથવા ઘટનાનો રિપોર્ટ સાચવવા ટૅપ કરો.',
      'volunteer_triage_show_qr': 'QR બતાવો',
      'volunteer_triage_tap_report': 'રિપોર્ટ',
      'volunteer_triage_qr_title': 'ઘટના હેન્ડઓફ QR',
      'volunteer_triage_qr_body': 'રચનાત્મક ડેટા માટે સ્ટાફ અથવા EMS સાથે શેર કરો.',
      'volunteer_triage_report_saved': 'રિપોર્ટ આ ઘટના હેઠળ સાચવ્યો.',
      'volunteer_triage_report_failed': 'રિપોર્ટ સાચવી શકાયો નહીં: ',
      'volunteer_victim_medical_offline_hint': 'SOS પેકેટમાંથી — ઑફલાઇન કેશમાંથી.',
      'volunteer_victim_consciousness_title': 'સચેતતા',
      'volunteer_victim_three_questions': 'પ્રારંભિક જવાબો',
      'volunteer_major_updates_log': 'ફક્ત મુખ્ય અપડેટ',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ટિયર {tier} સુધી વધારી રહ્યા છીએ. હોસ્પિટલ {hospital} પ્રયાસ કરી રહ્યા છીએ.',
      'volunteer_dispatch_trying_hospital': 'હોસ્પિટલ {hospital} પ્રયાસ કરી રહ્યા છીએ.',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} એ કટોકટી સ્વીકારી. એમ્બ્યુલન્સ સંકલન ચાલુ છે.',
      'volunteer_dispatch_all_hospitals_notified':
          'બધી હોસ્પિટલોને જાણ કરી. કટોકટી સેવાઓ તરફ લઈ જઈ રહ્યા છીએ.',
      'sos_dispatch_alerting_nearest_trying':
          'તમારા વિસ્તારની નજીકની હોસ્પિટલને સૂચિત કરી રહ્યા છીએ. {hospital} પ્રયાસ કરી રહ્યા છીએ.',
      'sos_dispatch_escalating_tier_trying':
          'પ્રતિસાદ નહીં. ટિયર {tier} સુધી વધારી રહ્યા છીએ. {hospital} પ્રયાસ કરી રહ્યા છીએ.',
      'sos_dispatch_retry_previous_trying':
          'પાછલી હોસ્પિટલ પાસેથી પ્રતિસાદ નહીં. {hospital} પ્રયાસ કરી રહ્યા છીએ.',
      'sos_dispatch_all_hospitals_call_112':
          'બધી હોસ્પિટલોને જાણ કરી. કટોકટી સેવાઓ માટે કૃપા કરીને 112 કૉલ કરો.',
    },

    // ── Punjabi (ਪੰਜਾਬੀ) ──────────────────────────────────────────────────
    'pa': {
      'app_name': 'EmergencyOS',
      'profile_title': 'ਪ੍ਰੋਫਾਈਲ ਅਤੇ ਮੈਡੀਕਲ ਆਈਡੀ',
      'language': 'ਭਾਸ਼ਾ',
      'save_medical_profile': 'ਮੈਡੀਕਲ ਪ੍ਰੋਫਾਈਲ ਸੇਵ ਕਰੋ',
      'critical_medical_info': 'ਮਹੱਤਵਪੂਰਨ ਡਾਕਟਰੀ ਜਾਣਕਾਰੀ',
      'emergency_contacts': 'ਐਮਰਜੈਂਸੀ ਸੰਪਰਕ',
      'golden_hour_details': 'ਗੋਲਡਨ ਅਵਰ ਵੇਰਵੇ',
      'sos_lock': 'SOS ਲਾਕ',
      'top_life_savers': 'ਸਿਖਰਲੇ ਜੀਵਨ ਰੱਖਿਅਕ',
      'lives_saved': 'ਬਚਾਈਆਂ ਜਾਨਾਂ',
      'active_alerts': 'ਕਿਰਿਆਸ਼ੀਲ ਚੇਤਾਵਨੀਆਂ',
      'rank': 'ਰੈਂਕ',
      'on_duty': 'ਡਿਊਟੀ ਤੇ',
      'standby': 'ਸਟੈਂਡਬਾਈ',
      'sos': 'SOS',
      'call_now': 'ਹੁਣੇ ਕਾਲ ਕਰੋ',
      'quick_guide': 'ਤੇਜ਼ ਗਾਈਡ',
      'detailed_instructions': 'ਵਿਸਤ੍ਰਿਤ ਹਿਦਾਇਤਾਂ',
      'red_flags': 'ਖ਼ਤਰੇ ਦੇ ਸੰਕੇਤ',
      'cautions': 'ਸਾਵਧਾਨੀਆਂ',
      'voice_walkthrough': 'ਵੌਇਸ ਗਾਈਡ',
      'playing': 'ਚੱਲ ਰਿਹਾ ਹੈ...',
      'swipe_next_guide': 'ਅਗਲੀ ਗਾਈਡ ਲਈ ਸਵਾਈਪ ਕਰੋ',
      'watch_video_guide': 'ਪੂਰੀ ਵੀਡੀਓ ਗਾਈਡ ਦੇਖੋ',
      'emergency_grid_scan': 'ਐਮਰਜੈਂਸੀ ਗਰਿੱਡ ਸਕੈਨ',
      'area_telemetry': 'ਖੇਤਰ ਟੈਲੀਮੈਟਰੀ ਅਤੇ ਖ਼ਤਰਾ ਸੂਚਕ',
      'report_hazard': 'ਖ਼ਤਰੇ ਦੀ ਰਿਪੋਰਟ ਕਰੋ',
      'todays_duty': 'ਅੱਜ ਦੀ ਡਿਊਟੀ',
      'blood_type': 'ਖ਼ੂਨ ਦਾ ਗਰੁੱਪ',
      'allergies': 'ਐਲਰਜੀ',
      'medical_conditions': 'ਡਾਕਟਰੀ ਸਥਿਤੀ',
      'contact_name': 'ਮੁੱਖ ਸੰਪਰਕ ਨਾਮ',
      'contact_phone': 'ਮੁੱਖ ਸੰਪਰਕ ਫ਼ੋਨ',
      'relationship': 'ਰਿਸ਼ਤਾ',
      'medications': 'ਮੌਜੂਦਾ ਦਵਾਈਆਂ',
      'organ_donor': 'ਅੰਗ ਦਾਨ ਸਥਿਤੀ',
      'good_morning': 'ਸ਼ੁਭ ਸਵੇਰ,',
      'good_afternoon': 'ਸ਼ੁਭ ਦੁਪਹਿਰ,',
      'good_evening': 'ਸ਼ੁਭ ਸ਼ਾਮ,',
      'hospitals': 'ਹਸਪਤਾਲ',
      'visual_walkthrough': 'ਵਿਜ਼ੂਅਲ ਗਾਈਡ',
      'lifeline': 'ਲਾਈਫ਼ਲਾਈਨ',
      'nav_home': 'ਘਰ',
      'nav_map': 'ਨਕਸ਼ਾ',
      'nav_grid': 'ਗ੍ਰਿਡ',
      'nav_profile': 'ਪ੍ਰੋਫ਼ਾਈਲ',
      'map_caching_offline_pct': 'ਔਫਲਾਈਨ ਲਈ ਖੇਤਰ ਕੈਸ਼ ਹੋ ਰਿਹਾ ਹੈ — {pct}%',
      'map_drill_practice_banner':
          'ਅਭਿਆਸ ਗ੍ਰਿਡ: ਪਲਸਿੰਗ ਪਿੰਨ = ਡੈਮੋ ਸਰਗਰਮ ਅਲਰਟ। ਪਰਤਾਂ ਲਈ ਨਕਸ਼ਾ ਫਿਲਟਰ — ਅਸਲ ਡਾਟਾ ਨਹੀਂ।',
      'map_recenter_tooltip': 'ਮੁੜ ਕੇਂਦਰਿਤ ਕਰੋ',
      'map_legend_hospital': 'ਹਸਪਤਾਲ',
      'map_legend_live_sos_history': 'ਲਾਈਵ SOS / ਇਤਿਹਾਸ',
      'map_legend_past_this_hex': 'ਪਿਛਲਾ (ਇਹ ਹੈਕਸ)',
      'map_legend_in_area': 'ਖੇਤਰ ਵਿੱਚ {n}',
      'map_legend_in_cell': 'ਸੈਲ ਵਿੱਚ {n}',
      'map_legend_volunteers_on_duty': 'ਡਿਊਟੀ \'ਤੇ ਸਵੈਇੱਛਕ',
      'map_legend_volunteers_in_grid': 'ਗ੍ਰਿਡ ਵਿੱਚ {n}',
      'map_legend_responder_scene': 'ਜਵਾਬਦੇਹ → ਦ੍ਰਿਸ਼',
      'map_responder_routes_one': '{n} ਰਸਤਾ',
      'map_responder_routes_many': '{n} ਰਸਤੇ',
      'map_filters_title': 'ਨਕਸ਼ਾ ਫਿਲਟਰ',
      'step_prefix': 'ਕਦਮ',
      'highlights_steps': 'ਇੱਕ-ਇੱਕ ਕਰਕੇ ਕਦਮ ਦਿਖਾਉਂਦਾ ਹੈ',
      'offline_mode': 'ਆਫ਼ਲਾਈਨ — ਨੈੱਟਵਰਕ ਕੱਟਿਆ',
      'volunteer': 'ਵਲੰਟੀਅਰ',
      'unranked': 'ਰੈਂਕ ਨਹੀਂ',
      'live': 'ਲਾਈਵ',
      'you': 'ਤੁਸੀਂ',
      'saved': 'ਬਚਾਏ',
      'xp_responses': 'XP · {0} ਜਵਾਬ',
      'duty_monitoring': 'ਜਦੋਂ ਤੁਸੀਂ ਡਿਊਟੀ ਤੇ ਹੋ SOS ਪੌਪ-ਅੱਪ ਚਾਲੂ ਹਨ।',
      'turn_on_duty_msg': 'SOS ਪੌਪ-ਅੱਪ ਪ੍ਰਾਪਤ ਕਰਨ ਲਈ ਡਿਊਟੀ ਚਾਲੂ ਕਰੋ।',
      'on_duty_snack': 'ਡਿਊਟੀ ਤੇ — ਤੁਹਾਡੇ ਖੇਤਰ ਵਿੱਚ ਘਟਨਾਵਾਂ ਦੀ ਨਿਗਰਾਨੀ...',
      'off_duty_snack': 'ਸਟੈਂਡਬਾਈ — ਡਿਊਟੀ ਸੈਸ਼ਨ ਰਿਕਾਰਡ ਕੀਤਾ।',
      'leaderboard_offline': 'ਲੀਡਰਬੋਰਡ ਆਫ਼ਲਾਈਨ',
      'leaderboard_offline_sub': 'ਸਿੰਕ ਰੁਕੀ। ਕੈਸ਼ ਸਕੋਰ।',
      'set_sos_pin_first': 'ਪਹਿਲਾਂ SOS ਪਿੰਨ ਸੈੱਟ ਕਰੋ',
      'set_pin_safety_msg': 'ਸੁਰੱਖਿਆ ਲਈ, SOS ਬਣਾਉਣ ਤੋਂ ਪਹਿਲਾਂ ਪਿੰਨ ਸੈੱਟ ਕਰਨਾ ਜ਼ਰੂਰੀ ਹੈ।',
      'set_pin_now': 'ਹੁਣੇ ਪਿੰਨ ਸੈੱਟ ਕਰੋ',
      'later': 'ਬਾਅਦ ਵਿੱਚ',
      'sos_are_you_conscious':
          'ਕੀ ਤੁਸੀਂ ਹੋਸ਼ ਵਿੱਚ ਹੋ? ਕਿਰਪਾ ਕਰਕੇ ਹਾਂ ਜਾਂ ਨਾਂ ਜਵਾਬ ਦਿਓ।',
      'sos_tts_opening_guidance':
          'ਤੁਹਾਡਾ SOS ਸਰਗਰਮ ਹੈ। ਮਦਦ ਆ ਰਹੀ ਹੈ। ਬੋਲੇ ਗਏ ਨਿਰਦੇਸ਼ਾਂ ਦੀ ਪਾਲਣਾ ਕਰੋ ਅਤੇ ਜਵਾਬ ਦੇਣ ਲਈ ਟੈਪ ਕਰੋ।',
      'sos_interview_q1_prompt': 'ਕੀ ਹੋ ਰਿਹਾ ਹੈ? (ਐਮਰਜੈਂਸੀ ਕਿਸਮ)',
      'sos_interview_q2_prompt': 'ਕੀ ਤੁਸੀਂ ਸੁਰੱਖਿਤ ਹੋ? ਕਿੰਨਾ ਗੰਭੀਰ?',
      'sos_interview_q3_prompt': 'ਕਿੰਨੇ ਲੋਕ ਸ਼ਾਮਲ ਹਨ?',
      'sos_chip_cat_accident': 'ਦੁਰਘਟਨਾ',
      'sos_chip_cat_medical': 'ਤਬੀਬੀ',
      'sos_chip_cat_hazard': 'ਖਤਰਾ (ਅੱਗ, ਡੁੱਬਣਾ ਆਦਿ)',
      'sos_chip_cat_assault': 'ਹਮਲਾ',
      'sos_chip_cat_other': 'ਹੋਰ',
      'sos_chip_safe_critical': 'ਗੰਭੀਰ (ਜਾਨਲੇਵਾ)',
      'sos_chip_safe_injured': 'ਜ਼ਖਮੀ ਪਰ ਸਥਿਰ',
      'sos_chip_safe_danger': 'ਜ਼ਖਮੀ ਨਹੀਂ ਪਰ ਖਤਰੇ ਵਿੱਚ',
      'sos_chip_safe_safe_now': 'ਹੁਣ ਸੁਰੱਖਿਤ',
      'sos_chip_people_me': 'ਸਿਰਫ ਮੈਂ',
      'sos_chip_people_two': 'ਦੋ',
      'sos_chip_people_many': 'ਦੋ ਤੋਂ ਵੱਧ',
      'sos_tts_interview_saved':
          'ਸਾਰਾ ਇੰਟਰਵਿਊ ਡੇਟਾ ਸੁਰੱਖਿਤ। ਜਵਾਬਦੇਹਾਂ ਕੋਲ ਵਿਸਤਾਰ ਹੈ।',
      'sos_tts_map_routes':
          'ਨਕਸ਼ਾ ਟੈਬ ਖੋਲ੍ਹੋ: ਲਾਲ ਨਿਯੁਕਤ ਹਸਪਤਾਲ ਦਾ ਸੜਕ ਰਸਤਾ ਜਾਂ ਨੇੜੇ ਦਾ ਰਸਤਾ; ਹਰਾ ਸਵੈਸੇਵਕ ਰਸਤਾ। ਐਮਰਜੈਂਸੀ ਵੌਇਸ ਚੈਨਲ ਤੇ ਰਹੋ।',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'ਕੋਈ ਜਵਾਬ ਨਹੀਂ। ਹੋਸ਼ ਜਾਂਚ {max} ਵਿੱਚੋਂ {n}। ਇੱਕ ਮਿੰਟ ਬਾਅਦ ਫਿਰ ਪੁੱਛਾਂਗੇ।',
      'volunteer_victim_medical_card': 'ਪੀੜਤ ਮੈਡੀਕਲ ਕਾਰਡ',
      'volunteer_dispatch_milestone_title': 'ਡਿਸਪੈਚ ਅੱਪਡੇਟ',
      'volunteer_dispatch_milestone_hospital': 'ਹਸਪਤਾਲ ਨੇ ਸਵੀਕਾਰ ਕੀਤਾ: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ਐਂਬੂਲੈਂਸ ਯੂਨਿਟ: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ਐਂਬੂਲੈਂਸ ਕਰੂ: ਤਾਲਮੇਲ…',
      'volunteer_dispatch_milestone_en_route': 'ਐਂਬੂਲੈਂਸ ਰਸਤੇ ਵਿੱਚ',
      'volunteer_triage_qr_report_title': 'QR ਜਾਂ ਟੈਪ ਰਿਪੋਰਟ',
      'volunteer_triage_qr_report_subtitle':
          'ਹੈਂਡਆਫ ਲਈ ਕੋਡ ਸਕੈਨ ਕਰੋ ਜਾਂ ਘਟਨਾ ਰਿਪੋਰਟ ਸੇਵ ਕਰਨ ਲਈ ਟੈਪ ਕਰੋ।',
      'volunteer_triage_show_qr': 'QR ਦਿਖਾਓ',
      'volunteer_triage_tap_report': 'ਰਿਪੋਰਟ',
      'volunteer_triage_qr_title': 'ਘਟਨਾ ਹੈਂਡਆਫ QR',
      'volunteer_triage_qr_body': 'ਸਟਰਕਚਰਡ ਡੇਟਾ ਲਈ ਸਟਾਫ ਜਾਂ EMS ਨਾਲ ਸਾਂਝਾ ਕਰੋ।',
      'volunteer_triage_report_saved': 'ਰਿਪੋਰਟ ਇਸ ਘਟਨਾ ਹੇਠ ਸੇਵ ਹੋਈ।',
      'volunteer_triage_report_failed': 'ਰਿਪੋਰਟ ਸੇਵ ਨਹੀਂ ਹੋ ਸਕੀ: ',
      'volunteer_victim_medical_offline_hint': 'SOS ਪੈਕੇਟ ਤੋਂ — ਔਫਲਾਈਨ ਕੈਸ਼ ਤੋਂ।',
      'volunteer_victim_consciousness_title': 'ਹੋਸ਼',
      'volunteer_victim_three_questions': 'ਸ਼ੁਰੂਆਤੀ ਜਵਾਬ',
      'volunteer_major_updates_log': 'ਸਿਰਫ਼ ਮੁੱਖ ਅੱਪਡੇਟ',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ਟੀਅਰ {tier} ਤੱਕ ਵਧਾ ਰਹੇ ਹਾਂ। ਹਸਪਤਾਲ {hospital} ਕੋਸ਼ਿਸ਼ ਕਰ ਰਹੇ ਹਾਂ।',
      'volunteer_dispatch_trying_hospital': 'ਹਸਪਤਾਲ {hospital} ਕੋਸ਼ਿਸ਼ ਕਰ ਰਹੇ ਹਾਂ।',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} ਨੇ ਐਮਰਜੈਂਸੀ ਸਵੀਕਾਰ ਕੀਤੀ। ਐਂਬੂਲੈਂਸ ਤਾਲਮੇਲ ਜਾਰੀ ਹੈ।',
      'volunteer_dispatch_all_hospitals_notified':
          'ਸਾਰੇ ਹਸਪਤਾਲਾਂ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ। ਐਮਰਜੈਂਸੀ ਸੇਵਾਵਾਂ ਵੱਲ ਭੇਜ ਰਹੇ ਹਾਂ।',
      'sos_dispatch_alerting_nearest_trying':
          'ਤੁਹਾਡੇ ਖੇਤਰ ਦੇ ਨੇੜਲੇ ਹਸਪਤਾਲ ਨੂੰ ਅਲਰਟ ਕਰ ਰਹੇ ਹਾਂ। {hospital} ਕੋਸ਼ਿਸ਼ ਕਰ ਰਹੇ ਹਾਂ।',
      'sos_dispatch_escalating_tier_trying':
          'ਕੋਈ ਜਵਾਬ ਨਹੀਂ। ਟੀਅਰ {tier} ਤੱਕ ਵਧਾ ਰਹੇ ਹਾਂ। {hospital} ਕੋਸ਼ਿਸ਼ ਕਰ ਰਹੇ ਹਾਂ।',
      'sos_dispatch_retry_previous_trying':
          'ਪਿਛਲੇ ਹਸਪਤਾਲ ਤੋਂ ਕੋਈ ਜਵਾਬ ਨਹੀਂ। {hospital} ਕੋਸ਼ਿਸ਼ ਕਰ ਰਹੇ ਹਾਂ।',
      'sos_dispatch_all_hospitals_call_112':
          'ਸਾਰੇ ਹਸਪਤਾਲਾਂ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ। ਐਮਰਜੈਂਸੀ ਸੇਵਾਵਾਂ ਲਈ ਕਿਰਪਾ ਕਰਕੇ 112 ਤੇ ਕਾਲ ਕਰੋ।',
    },

    // ── Odia (ଓଡ଼ିଆ) ──────────────────────────────────────────────────────
    'or': {
      'app_name': 'EmergencyOS',
      'profile_title': 'ପ୍ରୋଫାଇଲ ଏବଂ ମେଡିକାଲ ଆଇଡି',
      'language': 'ଭାଷା',
      'save_medical_profile': 'ମେଡିକାଲ ପ୍ରୋଫାଇଲ ସେଭ କରନ୍ତୁ',
      'critical_medical_info': 'ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ଚିକିତ୍ସା ତଥ୍ୟ',
      'emergency_contacts': 'ଜରୁରୀ ଯୋଗାଯୋଗ',
      'golden_hour_details': 'ଗୋଲ୍ଡେନ ଆୱାର ବିବରଣୀ',
      'sos_lock': 'SOS ଲକ',
      'top_life_savers': 'ସର୍ବୋଚ୍ଚ ଜୀବନ ରକ୍ଷାକାରୀ',
      'lives_saved': 'ବଞ୍ଚାଯାଇଥିବା ଜୀବନ',
      'active_alerts': 'ସକ୍ରିୟ ଆଲର୍ଟ',
      'rank': 'ର୍ୟାଙ୍କ',
      'on_duty': 'ଡ୍ୟୁଟିରେ',
      'standby': 'ଷ୍ଟାଣ୍ଡବାଇ',
      'sos': 'SOS',
      'call_now': 'ଏବେ କଲ କରନ୍ତୁ',
      'quick_guide': 'ଦ୍ରୁତ ଗାଇଡ',
      'detailed_instructions': 'ବିସ୍ତୃତ ନିର୍ଦ୍ଦେଶ',
      'red_flags': 'ବିପଦ ସଙ୍କେତ',
      'cautions': 'ସତର୍କତା',
      'voice_walkthrough': 'ଭଏସ ଗାଇଡ',
      'playing': 'ଚାଲୁଛି...',
      'swipe_next_guide': 'ପରବର୍ତ୍ତୀ ଗାଇଡ ପାଇଁ ସ୍ୱାଇପ କରନ୍ତୁ',
      'watch_video_guide': 'ସମ୍ପୂର୍ଣ୍ଣ ଭିଡିଓ ଗାଇଡ ଦେଖନ୍ତୁ',
      'emergency_grid_scan': 'ଜରୁରୀ ଗ୍ରିଡ ସ୍କାନ',
      'area_telemetry': 'ଅଞ୍ଚଳ ଟେଲିମେଟ୍ରି ଏବଂ ବିପଦ ସୂଚକ',
      'report_hazard': 'ବିପଦ ରିପୋର୍ଟ କରନ୍ତୁ',
      'todays_duty': 'ଆଜିର ଡ୍ୟୁଟି',
      'blood_type': 'ରକ୍ତ ଗ୍ରୁପ',
      'allergies': 'ଆଲର୍ଜି',
      'medical_conditions': 'ଚିକିତ୍ସା ଅବସ୍ଥା',
      'contact_name': 'ପ୍ରାଥମିକ ଯୋଗାଯୋଗ ନାମ',
      'contact_phone': 'ପ୍ରାଥମିକ ଯୋଗାଯୋଗ ଫୋନ',
      'relationship': 'ସମ୍ପର୍କ',
      'medications': 'ବର୍ତ୍ତମାନ ଔଷଧ',
      'organ_donor': 'ଅଙ୍ଗ ଦାନ ସ୍ଥିତି',
      'good_morning': 'ସୁପ୍ରଭାତ,',
      'good_afternoon': 'ଶୁଭ ଅପରାହ୍ନ,',
      'good_evening': 'ଶୁଭ ସନ୍ଧ୍ୟା,',
      'hospitals': 'ଡାକ୍ତରଖାନା',
      'visual_walkthrough': 'ଭିଜୁଆଲ ଗାଇଡ',
      'lifeline': 'ଲାଇଫଲାଇନ',
      'nav_home': 'ହୋମ',
      'nav_map': 'ମ୍ୟାପ',
      'nav_grid': 'ଗ୍ରିଡ୍',
      'nav_profile': 'ପ୍ରୋଫାଇଲ',
      'map_caching_offline_pct': 'ଅଫଲାଇନ୍ ପାଇଁ କ୍ଷେତ୍ର କ୍ୟାସ୍ ହେଉଛି — {pct}%',
      'map_drill_practice_banner':
          'ଅଭ୍ୟାସ ଗ୍ରିଡ୍: ପଲ୍ସିଂ ପିନ୍ = ଡେମୋ ସକ୍ରିୟ ସତର୍କତା। ସ୍ତର ପାଇଁ ମାନଚିତ୍ର ଫିଲ୍ଟର — ପ୍ରକୃତ ଡାଟା ନୁହେଁ।',
      'map_recenter_tooltip': 'ପୁନର୍କେନ୍ଦ୍ରିତ କରନ୍ତୁ',
      'map_legend_hospital': 'ଡାକ୍ତରଖାନା',
      'map_legend_live_sos_history': 'ଲାଇଭ୍ SOS / ଇତିହାସ',
      'map_legend_past_this_hex': 'ଅତୀତ (ଏହି ହେକ୍ସ)',
      'map_legend_in_area': 'କ୍ଷେତ୍ରରେ {n}',
      'map_legend_in_cell': 'ସେଲରେ {n}',
      'map_legend_volunteers_on_duty': 'ଡ୍ୟୁଟିରେ ସ୍ୱେଚ୍ଛାସେବୀ',
      'map_legend_volunteers_in_grid': 'ଗ୍ରିଡରେ {n}',
      'map_legend_responder_scene': 'ପ୍ରତିକ୍ରିୟାକାରୀ → ଦୃଶ୍ୟ',
      'map_responder_routes_one': '{n} ମାର୍ଗ',
      'map_responder_routes_many': '{n} ମାର୍ଗ',
      'map_filters_title': 'ମାନଚିତ୍ର ଫିଲ୍ଟର',
      'step_prefix': 'ପଦକ୍ଷେପ',
      'highlights_steps': 'ଗୋଟିଏ ଗୋଟିଏ କରି ପଦକ୍ଷେପ ଦେଖାଏ',
      'offline_mode': 'ଅଫଲାଇନ — ନେଟୱାର୍କ ବିଚ୍ଛିନ୍ନ',
      'volunteer': 'ସ୍ୱେଚ୍ଛାସେବୀ',
      'unranked': 'ର୍ୟାଙ୍କ ନାହିଁ',
      'live': 'ଲାଇଭ',
      'you': 'ଆପଣ',
      'saved': 'ବଞ୍ଚାଇଲେ',
      'xp_responses': 'XP · {0} ପ୍ରତିକ୍ରିୟା',
      'duty_monitoring': 'ଆପଣ ଡ୍ୟୁଟିରେ ଥିବାବେଳେ SOS ପପ-ଅପ ଚାଲୁ ଅଛି।',
      'turn_on_duty_msg': 'SOS ପପ-ଅପ ପାଇବା ପାଇଁ ଡ୍ୟୁଟି ଚାଲୁ କରନ୍ତୁ।',
      'on_duty_snack': 'ଡ୍ୟୁଟିରେ — ଆପଣଙ୍କ ଅଞ୍ଚଳରେ ଘଟଣା ନଜର ରଖୁଛି...',
      'off_duty_snack': 'ଷ୍ଟାଣ୍ଡବାଇ — ଡ୍ୟୁଟି ସେସନ ରେକର୍ଡ ହେଲା।',
      'leaderboard_offline': 'ଲୀଡରବୋର୍ଡ ଅଫଲାଇନ',
      'leaderboard_offline_sub': 'ସିଙ୍କ ବନ୍ଦ। କ୍ୟାସ ସ୍କୋର।',
      'set_sos_pin_first': 'ପ୍ରଥମେ SOS ପିନ ସେଟ କରନ୍ତୁ',
      'set_pin_safety_msg': 'ସୁରକ୍ଷା ପାଇଁ, SOS ସୃଷ୍ଟି କରିବା ପୂର୍ବରୁ ପିନ ସେଟ କରିବା ଆବଶ୍ୟକ।',
      'set_pin_now': 'ଏବେ ପିନ ସେଟ କରନ୍ତୁ',
      'later': 'ପରେ',
      'sos_are_you_conscious':
          'ଆପଣ ସଚେତ ଅଛନ୍ତି କି? ଦୟାକରି ହଁ କିମ୍ବା ନା ଉତ୍ତର ଦିଅନ୍ତୁ।',
      'sos_tts_opening_guidance':
          'ଆପଣଙ୍କ SOS ସକ୍ରିୟ। ସାହାଯ୍ୟ ଆସୁଛି। କୁହାଯାଇଥିବା ନିର୍ଦ୍ଦେଶ ଅନୁସରଣ କରନ୍ତୁ ଏବଂ ଉତ୍ତର ଦେବାକୁ ଟ୍ୟାପ୍ କରନ୍ତୁ।',
      'sos_interview_q1_prompt': 'କଣ ହେଉଛି? (ଜରୁରୀ ପ୍ରକାର)',
      'sos_interview_q2_prompt': 'ଆପଣ ସୁରକ୍ଷିତ କି? କେତେ ଗୁରୁତର?',
      'sos_interview_q3_prompt': 'କେତେ ଜଣ ଜଡିତ?',
      'sos_chip_cat_accident': 'ଦୁର୍ଘଟଣା',
      'sos_chip_cat_medical': 'ଚିକିତ୍ସା',
      'sos_chip_cat_hazard': 'ବିପଦ (ଅଗ୍ନି, ବୁଡିବା ଇତ୍ୟାଦି)',
      'sos_chip_cat_assault': 'ଆକ୍ରମଣ',
      'sos_chip_cat_other': 'ଅନ୍ୟ',
      'sos_chip_safe_critical': 'ଗୁରୁତର (ଜୀବନ ବିପଦ)',
      'sos_chip_safe_injured': 'ଆଘାତ କିନ୍ତୁ ସ୍ଥିର',
      'sos_chip_safe_danger': 'ଆଘାତ ନାହିଁ କିନ୍ତୁ ବିପଦରେ',
      'sos_chip_safe_safe_now': 'ଏବେ ସୁରକ୍ଷିତ',
      'sos_chip_people_me': 'କେବଳ ମୁଁ',
      'sos_chip_people_two': 'ଦୁଇଜଣ',
      'sos_chip_people_many': 'ଦୁଇଠାରୁ ଅଧିକ',
      'sos_tts_interview_saved':
          'ସମସ୍ତ ସାକ୍ଷାତକାର ଡାଟା ସେଭ୍ ହେଲା। ପ୍ରତିକ୍ରିୟାକାରୀଙ୍କ ପାଖରେ ବିବରଣୀ ଅଛି।',
      'sos_tts_map_routes':
          'ମ୍ୟାପ୍ ଟ୍ୟାବ୍ ଖୋଲନ୍ତୁ: ଲାଲ୍ ନିୟୁକ୍ତ ଡାକ୍ତରଖାନାକୁ ରାସ୍ତା କିମ୍ବା ନିକଟ ମାର୍ଗ; ସବୁଜ ସ୍ୱେଚ୍ଛାସେବୀ ମାର୍ଗ। ଜରୁରୀ ଭଏସ୍ ଚ୍ୟାନେଲରେ ରୁହନ୍ତୁ।',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'ଉତ୍ତର ନାହିଁ। ସଚେତନତା ଯାଞ୍ଚ {max} ରେ {n}। ଏକ ମିନିଟ୍ ପରେ ପୁନଃ ପଚାରିବୁ।',
      'volunteer_victim_medical_card': 'ପୀଡିତ ମେଡିକାଲ୍ କାର୍ଡ',
      'volunteer_dispatch_milestone_title': 'ଡିସପାଚ୍ ଅପଡେଟ୍',
      'volunteer_dispatch_milestone_hospital': 'ଡାକ୍ତରଖାନା ଗ୍ରହଣ କଲା: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ଆମ୍ବୁଲାନ୍ସ ୟୁନିଟ୍: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ଆମ୍ବୁଲାନ୍ସ କ୍ରୁ: ସମନ୍ୱୟ…',
      'volunteer_dispatch_milestone_en_route': 'ଆମ୍ବୁଲାନ୍ସ ମାର୍ଗରେ',
      'volunteer_triage_qr_report_title': 'QR କିମ୍ବା ଟ୍ୟାପ୍ ରିପୋର୍ଟ',
      'volunteer_triage_qr_report_subtitle':
          'ହ୍ୟାଣ୍ଡଅଫ୍ ପାଇଁ କୋଡ୍ ସ୍କାନ୍ କରନ୍ତୁ କିମ୍ବା ଘଟଣା ରିପୋର୍ଟ ସେଭ୍ ପାଇଁ ଟ୍ୟାପ୍ କରନ୍ତୁ।',
      'volunteer_triage_show_qr': 'QR ଦେଖାନ୍ତୁ',
      'volunteer_triage_tap_report': 'ରିପୋର୍ଟ',
      'volunteer_triage_qr_title': 'ଘଟଣା ହ୍ୟାଣ୍ଡଅଫ୍ QR',
      'volunteer_triage_qr_body': 'ଗଠନାତ୍ମକ ଡାଟା ପାଇଁ ଷ୍ଟାଫ୍ କିମ୍ବା EMS ସହ ସେୟାର୍ କରନ୍ତୁ।',
      'volunteer_triage_report_saved': 'ରିପୋର୍ଟ ଏହି ଘଟଣା ତଳେ ସେଭ୍ ହେଲା।',
      'volunteer_triage_report_failed': 'ରିପୋର୍ଟ ସେଭ୍ ହେଲା ନାହିଁ: ',
      'volunteer_victim_medical_offline_hint': 'SOS ପ୍ୟାକେଟ୍ ଠାରୁ — ଅଫଲାଇନ୍ କ୍ୟାଶରୁ।',
      'volunteer_victim_consciousness_title': 'ସଚେତନତା',
      'volunteer_victim_three_questions': 'ଆରମ୍ଭିକ ଉତ୍ତର',
      'volunteer_major_updates_log': 'କେବଳ ମୁଖ୍ୟ ଅପଡେଟ୍',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ଟିଅର {tier} ପର୍ଯ୍ୟନ୍ତ ବୃଦ୍ଧି କରୁଛୁ। ଡାକ୍ତରଖାନା {hospital} ଚେଷ୍ଟା କରୁଛୁ।',
      'volunteer_dispatch_trying_hospital': 'ଡାକ୍ତରଖାନା {hospital} ଚେଷ୍ଟା କରୁଛୁ।',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} ଜରୁରୀ ଗ୍ରହଣ କଲା। ଆମ୍ବୁଲାନ୍ସ ସମନ୍ୱୟ ଚାଲିଛି।',
      'volunteer_dispatch_all_hospitals_notified':
          'ସମସ୍ତ ଡାକ୍ତରଖାନାକୁ ସୂଚିତ କଲୁ। ଜରୁରୀ ସେବାକୁ ବଢ଼ାଉଛୁ।',
      'sos_dispatch_alerting_nearest_trying':
          'ଆପଣଙ୍କ ଅଞ୍ଚଳର ନିକଟତମ ଡାକ୍ତରଖାନାକୁ ସତର୍କ କରୁଛୁ। {hospital} ଚେଷ୍ଟା କରୁଛୁ।',
      'sos_dispatch_escalating_tier_trying':
          'କୌଣସି ଉତ୍ତର ନାହିଁ। ଟିଅର {tier} ପର୍ଯ୍ୟନ୍ତ ବୃଦ୍ଧି କରୁଛୁ। {hospital} ଚେଷ୍ଟା କରୁଛୁ।',
      'sos_dispatch_retry_previous_trying':
          'ପୂର୍ବ ଡାକ୍ତରଖାନାରୁ ଉତ୍ତର ନାହିଁ। {hospital} ଚେଷ୍ଟା କରୁଛୁ।',
      'sos_dispatch_all_hospitals_call_112':
          'ସମସ୍ତ ଡାକ୍ତରଖାନାକୁ ସୂଚିତ କଲୁ। ଜରୁରୀ ସେବା ପାଇଁ ଦୟାକରି 112 କୁ କଲ୍ କରନ୍ତୁ।',
    },

    // ── Urdu (اردو) ────────────────────────────────────────────────────────
    'ur': {
      'app_name': 'EmergencyOS',
      'profile_title': 'پروفائل اور میڈیکل آئی ڈی',
      'language': 'زبان',
      'save_medical_profile': 'طبی پروفائل محفوظ کریں',
      'critical_medical_info': 'اہم طبی معلومات',
      'emergency_contacts': 'ایمرجنسی رابطے',
      'golden_hour_details': 'گولڈن آور تفصیلات',
      'sos_lock': 'SOS لاک',
      'top_life_savers': 'سرفہرست جان بچانے والے',
      'lives_saved': 'بچائی گئی جانیں',
      'active_alerts': 'فعال الرٹس',
      'rank': 'درجہ',
      'on_duty': 'ڈیوٹی پر',
      'standby': 'اسٹینڈبائی',
      'sos': 'SOS',
      'call_now': 'ابھی کال کریں',
      'quick_guide': 'فوری رہنمائی',
      'detailed_instructions': 'تفصیلی ہدایات',
      'red_flags': 'خطرے کے اشارے',
      'cautions': 'احتیاطیں',
      'voice_walkthrough': 'وائس رہنمائی',
      'playing': 'چل رہا ہے...',
      'swipe_next_guide': 'اگلی رہنمائی کے لیے سوائپ کریں',
      'watch_video_guide': 'مکمل ویڈیو گائیڈ دیکھیں',
      'emergency_grid_scan': 'ایمرجنسی گرڈ سکین',
      'area_telemetry': 'علاقائی ٹیلی میٹری اور خطرے کا اشاریہ',
      'report_hazard': 'خطرے کی اطلاع دیں',
      'todays_duty': 'آج کی ڈیوٹی',
      'blood_type': 'خون کا گروپ',
      'allergies': 'الرجی',
      'medical_conditions': 'طبی حالت',
      'contact_name': 'بنیادی رابطے کا نام',
      'contact_phone': 'بنیادی رابطے کا فون',
      'relationship': 'رشتہ',
      'medications': 'موجودہ ادویات',
      'organ_donor': 'عضو عطیہ کی حیثیت',
      'good_morning': 'صبح بخیر،',
      'good_afternoon': 'دوپہر بخیر،',
      'good_evening': 'شام بخیر،',
      'hospitals': 'ہسپتال',
      'visual_walkthrough': 'بصری رہنمائی',
      'lifeline': 'لائف لائن',
      'nav_home': 'ہوم',
      'nav_map': 'نقشہ',
      'nav_grid': 'گرڈ',
      'nav_profile': 'پروفائل',
      'map_caching_offline_pct': 'آف لائن کے لیے علاقہ کیش ہو رہا ہے — {pct}%',
      'map_drill_practice_banner':
          'مشق گرڈ: پلسنگ پن = ڈیمو فعال الرٹس۔ پرتوں کے لیے نقشہ فلٹر — حقیقی ڈیٹا نہیں۔',
      'map_recenter_tooltip': 'دوبارہ مرکز میں لائیں',
      'map_legend_hospital': 'ہسپتال',
      'map_legend_live_sos_history': 'لائیو SOS / تاریخ',
      'map_legend_past_this_hex': 'گزشتہ (یہ ہیکس)',
      'map_legend_in_area': 'علاقے میں {n}',
      'map_legend_in_cell': 'سیل میں {n}',
      'map_legend_volunteers_on_duty': 'ڈیوٹی پر رضاکار',
      'map_legend_volunteers_in_grid': 'گرڈ میں {n}',
      'map_legend_responder_scene': 'جواب دہندہ → منظر',
      'map_responder_routes_one': '{n} راستہ',
      'map_responder_routes_many': '{n} راستے',
      'map_filters_title': 'نقشہ فلٹر',
      'step_prefix': 'قدم',
      'highlights_steps': 'ایک ایک کر کے قدم دکھاتا ہے',
      'offline_mode': 'آف لائن — نیٹ ورک منقطع',
      'volunteer': 'رضاکار',
      'unranked': 'درجہ نہیں',
      'live': 'لائیو',
      'you': 'آپ',
      'saved': 'بچائے',
      'xp_responses': 'XP · {0} جوابات',
      'duty_monitoring': 'جب آپ ڈیوٹی پر ہیں تو SOS پاپ اپ آن ہیں۔',
      'turn_on_duty_msg': 'SOS پاپ اپ حاصل کرنے کے لیے ڈیوٹی آن کریں۔',
      'on_duty_snack': 'ڈیوٹی پر — آپ کے علاقے میں واقعات کی نگرانی...',
      'off_duty_snack': 'اسٹینڈبائی — ڈیوٹی سیشن ریکارڈ ہوا۔',
      'leaderboard_offline': 'لیڈربورڈ آف لائن',
      'leaderboard_offline_sub': 'سنک رکی۔ کیش سکور۔',
      'set_sos_pin_first': 'پہلے SOS پن سیٹ کریں',
      'set_pin_safety_msg': 'حفاظت کے لیے، SOS بنانے سے پہلے پن سیٹ کرنا ضروری ہے۔',
      'set_pin_now': 'ابھی پن سیٹ کریں',
      'later': 'بعد میں',
      'sos_screen_title': 'SOS',
      'sos_hold_banner': 'بھیجنے کے لیے 3 سیکنڈ دبائے رکھیں۔',
      'sos_hold_button': 'SOS بھیجنے کے لیے دبائے رکھیں',
      'sos_semantics_hold_hint': 'SOS۔ بھیجنے کے لیے تین سیکنڈ دبائے رکھیں۔',
      'home_duty_heading': 'آج کی ڈیوٹی',
      'home_duty_progress': '{done}/{total} مکمل',
      'home_map_semantics': 'آپ کا علاقہ اور مقام دکھانے والا نقشہ',
      'home_recenter_map': 'نقشہ اپنے مقام پر مرکز کریں',
      'home_sos_large_fab_hint': 'ایمرجنسی الرٹ کے لیے SOS الٹی گنتی کھولیں',
      'home_sos_cancelled_snack': 'SOS منسوخ۔',
      'home_sos_sent_snack': 'SOS بھیجا گیا! ایمرجنسی سروسز کو مطلع کیا گیا۔',
      'quick_sos_title': 'فوری SOS',
      'quick_sos_subtitle': 'جواب دیں — تفصیلات سے مدد جلدی آتی ہے',
      'quick_sos_practice_banner':
          'مشق گائیڈڈ انٹیک — جمع کرنے سے اصلی SOS نہیں بنے گا۔',
      'quick_sos_section_what': 'ایمرجنسی کیا ہے؟',
      'quick_sos_section_someone_else': 'کیا آپ کسی اور کے لیے SOS چلا رہے ہیں؟',
      'quick_sos_send_now': 'ابھی SOS بھیجیں',
      'quick_sos_select_first': 'ایمرجنسی منتخب کریں اور تصدیق کریں',
      'quick_sos_section_victim': 'متاثرہ کی حالت',
      'quick_sos_victim_subtitle': 'جواب دہندگان کو صحیح سامان تیار کرنے میں مدد',
      'quick_sos_section_people': 'کتنے لوگوں کو مدد درکار؟',
      'quick_sos_yes_someone_else': 'ہاں — کسی اور کے لیے',
      'quick_sos_no_for_me': 'نہیں — میرے لیے',
      'quick_sos_other_hint': 'اپنی صورت حال مختصراً بیان کریں...',
      'quick_sos_close': 'فوری SOS بند کریں',
      'quick_sos_drill_submit_disabled':
          'مشق: جمع کرانا غیر فعال۔ ڈرل کے لیے ہوم پر سرخ SOS 3 سیکنڈ دبائیں۔',
      'quick_sos_failed': 'SOS ناکام: {detail}',
      'quick_sos_could_not_start': 'SOS شروع نہیں ہو سکا۔ دوبارہ کوشش کریں۔',
      'quick_sos_victim_conscious_q': 'کیا شخص ہوش میں ہے؟',
      'sos_are_you_conscious':
          'کیا آپ ہوش میں ہیں؟ براہ کرم ہاں یا نہیں جواب دیں۔',
      'sos_tts_opening_guidance':
          'آپ کا SOS فعال ہے۔ مدد آ رہی ہے۔ بولے گئے اشاروں کی پیروی کریں اور جواب دینے کے لیے ٹیپ کریں۔',
      'sos_interview_q1_prompt': 'کیا ہو رہا ہے؟ (ایمرجنسی کی قسم)',
      'sos_interview_q2_prompt': 'کیا آپ محفوظ ہیں؟ کتنا سنگین؟',
      'sos_interview_q3_prompt': 'کتنے لوگ شامل ہیں؟',
      'sos_chip_cat_accident': 'حادثہ',
      'sos_chip_cat_medical': 'طبی',
      'sos_chip_cat_hazard': 'خطرہ (آگ، ڈوبنا وغیرہ)',
      'sos_chip_cat_assault': 'حملہ',
      'sos_chip_cat_other': 'دیگر',
      'sos_chip_safe_critical': 'سنگین (جان لیوا)',
      'sos_chip_safe_injured': 'زخمی مگر مستحکم',
      'sos_chip_safe_danger': 'زخمی نہیں مگر خطرے میں',
      'sos_chip_safe_safe_now': 'اب محفوظ',
      'sos_chip_people_me': 'صرف میں',
      'sos_chip_people_two': 'دو',
      'sos_chip_people_many': 'دو سے زیادہ',
      'sos_tts_interview_saved':
          'متاثرہ انٹرویو ڈیٹا محفوظ۔ جواب دہندگان کے پاس تفصیل ہے۔',
      'sos_tts_map_routes':
          'نقشہ ٹیب کھولیں: سرخ مقررہ ہسپتال کا سڑک کا راستہ یا قریبی راستہ؛ سبز رضاکار کا راستہ۔ ایمرجنسی وائس چینل پر رہیں۔',
      'sos_tts_emergency_contacts_on_file':
          'Your emergency contact from your profile is attached to this SOS. SMS updates may be sent when that option is enabled.',
      'sos_tts_conscious_no_answer_attempt':
          'کوئی جواب نہیں۔ ہوش کی جانچ {max} میں سے {n}۔ ایک منٹ بعد پھر پوچھیں گے۔',
      'volunteer_victim_medical_card': 'متاثرہ میڈیکل کارڈ',
      'volunteer_dispatch_milestone_title': 'ڈسپیچ اپ ڈیٹس',
      'volunteer_dispatch_milestone_hospital': 'ہسپتال نے قبول کیا: {hospital}',
      'volunteer_dispatch_milestone_unit': 'ایمبولینس یونٹ: {unit}',
      'volunteer_dispatch_milestone_crew_pending': 'ایمبولینس عملہ: ہم آہنگی…',
      'volunteer_dispatch_milestone_en_route': 'ایمبولینس راستے میں',
      'volunteer_triage_qr_report_title': 'QR یا ٹیپ رپورٹ',
      'volunteer_triage_qr_report_subtitle':
          'ہینڈ آف کے لیے کوڈ اسکین کریں یا واقعے کی رپورٹ محفوظ کرنے کے لیے ٹیپ کریں۔',
      'volunteer_triage_show_qr': 'QR دکھائیں',
      'volunteer_triage_tap_report': 'رپورٹ',
      'volunteer_triage_qr_title': 'واقعہ ہینڈ آف QR',
      'volunteer_triage_qr_body': 'ساختی ڈیٹا کے لیے عملے یا EMS کے ساتھ شیئر کریں۔',
      'volunteer_triage_report_saved': 'رپورٹ اس واقعے کے تحت محفوظ ہو گئی۔',
      'volunteer_triage_report_failed': 'رپورٹ محفوظ نہیں ہو سکی: ',
      'volunteer_victim_medical_offline_hint': 'SOS پیکٹ سے — آف لائن کیش سے۔',
      'volunteer_victim_consciousness_title': 'ہوش',
      'volunteer_victim_three_questions': 'ابتدائی جوابات',
      'volunteer_major_updates_log': 'صرف اہم اپ ڈیٹس',
      'volunteer_dispatch_escalating_tier_trying_hospital':
          'ٹیئر {tier} تک بڑھا رہے ہیں۔ ہسپتال {hospital} آزما رہے ہیں۔',
      'volunteer_dispatch_trying_hospital': 'ہسپتال {hospital} آزما رہے ہیں۔',
      'volunteer_dispatch_hospital_accepted':
          '{hospital} نے ایمرجنسی قبول کی۔ ایمبولینس ہم آہنگی جاری ہے۔',
      'volunteer_dispatch_all_hospitals_notified':
          'تمام ہسپتالوں کو مطلع کیا۔ ایمرجنسی خدمات تک بڑھا رہے ہیں۔',
      'sos_dispatch_alerting_nearest_trying':
          'آپ کے علاقے کے قریب ترین ہسپتال کو الرٹ کر رہے ہیں۔ {hospital} آزما رہے ہیں۔',
      'sos_dispatch_escalating_tier_trying':
          'کوئی جواب نہیں۔ ٹیئر {tier} تک بڑھا رہے ہیں۔ {hospital} آزما رہے ہیں۔',
      'sos_dispatch_retry_previous_trying':
          'پچھلے ہسپتال سے کوئی جواب نہیں۔ {hospital} آزما رہے ہیں۔',
      'sos_dispatch_all_hospitals_call_112':
          'تمام ہسپتالوں کو مطلع کیا۔ ایمرجنسی خدمات کے لیے براہ کرم 112 پر کال کریں۔',
      'quick_sos_victim_breathing_q': 'کیا شخص سانس لے رہا ہے؟',
      'quick_sos_label_yes': 'ہاں',
      'quick_sos_label_no': 'نہیں',
      'quick_sos_label_unsure': 'یقین نہیں',
      'quick_sos_person': 'شخص',
      'quick_sos_people': 'افراد',
      'quick_sos_people_three_plus': '۳+',
      'login_tagline': 'جانیں بچائیں',
      'login_subtitle':
          'ایمرجنسی رپورٹ کریں، رضاکاروں سے رابطہ کریں، گولڈن آور میں جانیں بچائیں۔',
      'login_continue_google': 'Google سے جاری رکھیں',
      'login_continue_phone': 'فون سے جاری رکھیں',
      'login_send_code': 'تصدیقی کوڈ بھیجیں',
      'login_verify_login': 'تصدیق کریں اور لاگ ان',
      'login_phone_label': 'فون نمبر',
      'login_phone_hint': '+923001234567',
      'login_otp_label': 'تصدیقی کوڈ (OTP)',
      'login_back_options': 'اختیارات پر واپس',
      'login_change_phone': 'فون نمبر بدلیں',
      'login_drill_mode': 'ڈرل موڈ',
      'login_drill_subtitle': 'مشق کے لیے ٹیپ — کوئی حقیقی SOS نہیں',
      'login_drill_semantics': 'ڈرل موڈ، حقیقی ایمرجنسی کے بغیر مشق',
      'login_practise_victim': 'متاثرہ کے طور پر مشق',
      'login_practise_volunteer': 'رضاکار کے طور پر مشق',
      'login_admin_note':
          'ماسٹر کنسول: الگ اکاؤنٹ نہیں — نیچے ٹیپ کریں۔ لاگ ان نہ ہونے پر ہلکا گمنام سیشن۔',
      'login_ems_dashboard': 'EMS ڈیش بورڈ',
      'login_emergency_operator': 'ایمرجنسی سروس آپریٹر لاگ ان',
      'ai_assist_practice_banner':
          'مشق Lifeline — حقیقی ڈسپیچ پر کچھ نہیں جاتا۔',
      'ai_assist_rail_semantics': 'Lifeline سطح {n}: {title}',
      'ai_assist_emergency_toggle_on': 'ایمرجنسی موڈ آن، فوری رہنمائی',
      'ai_assist_emergency_toggle_off': 'ایمرجنسی موڈ آف',
      'dashboard_exit_drill_title': 'ڈرل موڈ سے باہر؟',
      'dashboard_exit_drill_body':
          'آپ مشق سیشن سے سائن آؤٹ ہو کر لاگ ان پر واپس جائیں گے۔',
      'dashboard_back_login_tooltip': 'لاگ ان پر واپس',
      'dashboard_exit_drill_confirm': 'باہر نکلیں',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'ta', 'te', 'kn', 'ml', 'bn', 'mr', 'gu', 'pa', 'or', 'ur']
          .contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
