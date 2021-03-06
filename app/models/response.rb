class Response

  def initialize(intent:, substance:, replies:, interaction_substance: nil)
    @intent = intent
    @substance_name = substance
    @ix_substance_name = interaction_substance
    @substance = nil
    @interaction_substance = nil
    @replies = replies
  end

  def create_reply
    return @replies if @replies.present?
    find_substances
    reply = create_reply_from_intent_and_substance
    [{ type: 'text', content: reply }]
  end

  private

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def human_intent
    case @intent
    when 'interactions_info'
      'interactions'
    when 'substance_info'
      'general substance info'
    when 'testing_info'
      'testing substances for purity'
    when 'dosage_info'
      'dosing info'
    when 'effects_info'
      'info on effects of a substance'
    when 'duration_info'
      'duration information'
    when 'safety_profile'
      'substance safety'
    when 'toxicity_profile'
      'the toxicity of a substance'
    when 'tolerance_profile'
      'tolerance and cross tolerances'
    else
      "...actually I'm not sure what you wanted to know about"
    end
  end

  def message_for_intent_and_substance
    case @intent
    when 'interactions_info'
      report_interactions
    when 'substance_info'
      @substance.substance_profile
    when 'testing_info'
      @substance.testing_profile
    when 'dosage_info'
      @substance.dose_profile
    when 'effects_info'
      @substance.effects_profile
    when 'duration_info'
      @substance.duration_profile
    when 'safety_profile'
      @substance.safety_profile
    when 'toxicity_profile'
      @substance.toxicity_profile
    when 'tolerance_profile'
      @substance.tolerance_profile
    else
      Rails.logger.info "Intent should have been caught: #{@intent}"
      "Sorry, I didn't know what you meant"
    end
  end
  # rubocop:enable

  # think about starting to move these out of Response model
  def report_interactions
    if @substance && !@interaction_substance
      return "Sorry, I know you want to know about mixing something with #{@substance.name}, but I'm not sure what"
    end
    interaction = Interaction.find_any_interaction(@substance, @interaction_substance)
    interaction = fetch_interactions_for(@substance.name, @interaction_substance.name) unless interaction
    return interaction.message if interaction
    "Sorry I couldn't find interaction info"
  end

  def fetch_interactions_for(drug1, drug2)
    interactions = TripSit::SubstanceRequester.interaction_lookup(drug1: drug1, drug2: drug2)
    status = interactions[:status]
    note = interactions[:note]
    return nil unless status
    Interaction.create(substance_a: @substance, substance_b: @interaction_substance,
                       status: status, notes: note)
  end

  def find_substances
    @substance = Drug.find_with_aliases(@substance_name)
    @interaction_substance = Drug.find_with_aliases(@ix_substance_name)
  end

  def create_reply_from_intent_and_substance
    if !@intent || @intent == 'unknown'
      could_not_determine_intent
    elsif !@substance
      could_not_determine_substance
    else
      message_for_intent_and_substance
    end
  end

  def could_not_determine_substance
    message = "Sorry, but I couldn't determine what substance you were inquiring about, "
    message += "but I think you wanted to know about #{human_intent}."
    message
  end

  def could_not_determine_intent
    message = if @substance
                "I could tell you want info about #{@substance.name}, but not what type of info. "
              else
                "Sorry, but I couldn't tell what you wanted. "
              end
    message += 'You can try "info about [substance]" or ask another question. I have info about '
    message += 'effects, toxicity, dose information, purity testing, tolerance, safety, or drug interactions.'
    message
  end
end
