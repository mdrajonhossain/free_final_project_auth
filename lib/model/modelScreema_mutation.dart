const String loginMutation = """
mutation Login(
  \$email: String!, 
  \$password: String, 
  \$companyId: String, 
  \$code: String,
  \$step: String,
  \$deviceId: String!,
  \$sessionToken: String
) {
  login(
    input: {
      email: \$email,
      password: \$password,
      step: \$step,
      device_type: "mobile",
      ipAddress: "sadf",
      countryName: null,
      time: null,
      city: null,
      device_id: \$deviceId,
      company_id: \$companyId,
      code: \$code,
      session_token: \$sessionToken
    }
  ) {
    token
    refresh_token
    status
    status_code
    message
    next_step
    session_token
    companies {
        company_id
        company_name
        # created_by
        # updated_by
        # company_img
        # role
        # industry
        # domain_name
        # plan_name
        # plan_user_limit
        # plan_storage_limit
        # is_deactivate
        # plan_id
        # subscription_id
        # product_id
        # price_id
        # class
        # campus
        # section
        # plan_access
        # created_at
        # updated_at
        # createdAt
        # updatedAt
        # team_title
        # company_size
        # hear_about
        # phone_number
        # company_email
        # company_address
        # company_website
        # business_type
        # registration_number
        # tin_number
        # social_link
        # module
        # created_by_role
        # company_contact_person
        # same_address
    }
  }
}
""";

const String sendMessageMutation = """
mutation send_msg(\$input: msgInput!) {
  send_msg(input: \$input) {
    msg {
      conversation_id
      msg_id
      msg_body
      edit_history
      msg_type
      is_secret
      cost_id
      file_group
      task_id
      img_url
      has_tag_text
      task_data {
        _id
        project_id
        project_title
        project_img
        conversation_id
        conversation_name
        conversation_img
        key_words
        msg_id
        task_title
        start_date
        end_date
        due_time
        progress
        status
        notes
        description
        description_by
        description_at
        assign_to
        assign_at
        observers
        forecasted_cost
        actual_cost
        cost_variance
        forecasted_hours
        actual_hours
        hours_variance
        repeat_task
        repeat_until
        priority
        is_archive
        review
        created_by
        created_at
        last_updated_at
        company_id
        participants
        view_status
        view_cost
        view_hour
        view_description
        view_note
        view_checklist
        view_update
        review_status
        flag
        has_delete
        owned_by
        owned_status
        owned_at
      }
      all_attachment {
        id
        conversation_id
        conversation_title
        user_id
        msg_id
        bucket
        file_type
        key
        location
        originalname
        file_size
        has_tag
        root_conv_id
        url_short_id
        file_category
        main_msg_id
        company_id
        referenceId
        reference_type
        uploaded_by
        is_delete
        is_secret
        created_at
        has_delete
        tag_list
        mention_user
        secret_user
        participants
        star
        tag_list_with_user {
          tag_id
          created_by
        }
        tag_list_details {
          tag_id
          tagged_by
          title
          company_id
          type
          shared_tag
          visibility
          tag_type
          tag_color
          team_list
          created_at
          update_at
        }
      }
      fnln
      is_reply_msg
      sender_is_active
      created_at
      forward_by
      has_emoji {
        grinning
        joy
        open_mouth
        disappointed_relieved
        rage
        thumbsup
        heart
        folded_hands
        check_mark
      }
      has_reply_attach
      has_reply
      has_delete
      last_reply_name
      last_reply_time
      has_flagged
      senderimg
      sendername
      secret_user
      reply_for_msgid
      participants
      sender
      senderemail
      url_base_title
      url_title
      url_body
      link_data {
        url_id
        url
        title
        msg_id
        conversation_id
        user_id
      }
    }
  }
}
""";

const String editMessageMutation = """
mutation Edit_msg(\$input: editInput!) {
  edit_msg(input: \$input) {
    status
    msg {
      conversation_id
      msg_id
      sender
      senderemail
      senderimg
      fnln
      sendername
      msg_body
      unread_reply
      msg_type
      reply_for_msgid
      last_reply_name
      is_reply_msg
      edit_status
      edit_history
      created_at
      last_reply_time
      last_update_time
      conv_title
      conv_img
      short_id
    }
  }
}
""";

const String deleteMessageMutation = """
mutation Delete_msg(\$input: deleteInput!) {
  delete_msg(input: \$input) {
    status
    data
    message
    __typename
  }
}
""";

const String forwardMutation = """
mutation Forward(
  \$conversation_id: String!,
  \$msg_id: String!,
  \$is_reply_msg: String!,
  \$conversation_lists: [String!]!
) {
  forward(
    input: {
      conversation_id: \$conversation_id
      msg_id: \$msg_id
      is_reply_msg: \$is_reply_msg
      conversation_lists: \$conversation_lists
    }
  ) {
    status
    message
    data
  }
}
""";

const String AddRemove_Tag_Into_File = """
mutation Add_remove_tag_into_file(\$input: addRemoveTagIntoFile!) {
  add_remove_tag_into_file(input: \$input) {
    status
    message
    data
    __typename
  }
}
""";

const String FileStarMutation = """
mutation File_star(\$input: starFileInput!) {
  file_star(input: \$input) {
    file_id
    star
    conversation_id
    msg_id
    file_bucket
    file_key
    is_reply_msg
  }
}
""";
