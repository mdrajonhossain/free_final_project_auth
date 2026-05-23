const String getAllUsersQuery = """
  query users (\$company_id: String!){
    users(company_id: \$company_id) {
      id
      firstname
      lastname
      email
      company_id
      phone
      img
      fnln
      role
      access
      email_otp
      email_otp_created_at
      login_total
      is_delete
      is_active
      eod_report
      createdat
      created_by
      erpNext
      erpNextPass
      erpNextRoles
    }
  }
""";

const String myQuery = """
query Me {
  me {
        id
        firstname
        lastname
        email
        company_id
        company_name
        fnln
        # dept
        # designation
        # account_type
        # lat
        # log
        # gcm_id
        img
        role
        # reset_id
        # conference_id
        # created_by
        # updated_by
        # updated_at
        # class
        # section
        # campus
        # company
        # parent_id
        # student_id
        # relationship
        # login_id
        # roll_number
        # birth_day
        # mobile_otp
        # email_otp
        # verified
        # last_login_address
        # gender
        # blood_group
        # marital_status
        # nickname
        # present_address
        # permanent_address
        # employee_id
        # nid
        # intro
        # father_name
        # mother_name
        # do_not_disturb
        # screen_time_today
        # face_detection
        # finger_detection
        # vacation_mode
        # in_time_today
        # out_time_today
        # phone_optional
        # school
        short_id
        # mute
        # short_id_guest
        # customer_id
        timezone
        # email_send_time
        is_active
        # is_delete
        # is_busy
        login_total
        # login_attempt
        # mute_all
        eod_report
        # ticket_report
        # digest_email
        sso
        phone
        # device
        access
        # pin_access
        # unpin_access
        # fcm_id
        # student_list
        # parent_list
        # relationship_map
        # user_friend_list
        # connected_device
        # blocked_list
        # interests
        # company_list
        # student_link
        # last_login
        # email_otp_created_at
        # createdat
        createdAt
        updatedAt
        erpNext
        erpNextPass
        erpNextRoles
        multi_company
  }
}
""";

const String roomsQuery = """
  query Rooms(\$userId: String!) {
    rooms(user_id: \$userId) {
      conversation_id
      # created_by
      title
      group
      # team_id
      # privacy
      # archive
      # status
      conv_img
      # topic_type
      # b_unit_id
      # room_id
      # is_busy
      company_id
      last_msg
      # sender_id
      # conference_id
      # root_conv_id
      # reset_id
      # system_conversation
      # system_conversation_active
      # short_id
      # close_for
      # friend_id
      # conv_is_active
      participants
      participants_name
      # participants_admin
      # participants_guest
      # is_active
      # is_pinned_users
      # tag_list
      # team_id_name
      # b_unit_id_name
      # system_conversatio_is_active
      # system_conversatio_send_sms
      pin
      # has_mute
      # mute
      # temp_user
      # created_at
      last_msg_time
    }
  }
""";

const String messagesQuery = """
query Messages(\$conversationId: String!, \$page: Int!) {
    messages(conversation_id: \$conversationId, page: \$page) {
        msgs {
            conversation_id
            msg_id
            sender
            senderemail
            senderimg
            fnln
            sendername
            msg_body
            unread_reply
            # call_duration
            # call_msg
            # call_type
            # call_status
            # call_sender_ip
            # call_sender_device
            # call_receiver_ip
            # call_receiver_device
            # call_server_addr
            msg_type
            reply_for_msgid
            last_reply_name
            is_reply_msg
            # root_msg_id
            # activity_id
            # url_favicon
            # url_base_title
            # url_title
            # url_body
            # url_image
            # has_timer
            # edit_status
            # last_update_user
            # conference_id
            # forward_by
            # msg_text
            # img_url
            # edit_history
            # root_conv_id
            # user_tag_string
            # company_id
            # task_id
            # referenceId
            # reference_type
            # file_group
            # cost_id
            # sender_is_active
            # task_start_date
            # task_due_date
            # updatedmsgid
            # old_created_time
            # has_delivered
            # has_reply
            # has_reply_attach
            # call_running
            # call_server_switch
            # is_secret
            # participants
            # call_participants
            # has_flagged
            # msg_status
            # attch_imgfile
            # attch_audiofile
            # attch_videofile
            # attch_otherfile
            # edit_seen
            # has_delete
            # has_hide
            # has_tag_text
            # tag_list
            # issue_accept_user
            # secret_user
            # mention_user
            # has_star
            # assign_to
            # task_observers
            created_at
            last_reply_time
            last_update_time
            # forward_at
            conv_title
            conv_img
            short_id
            all_attachment {
                id
                conversation_id
                # conversation_title
                # group
                # user_id
                # msg_id
                # bucket
                # file_type
                # key
                location
                originalname
                file_size
                # has_tag
                # root_conv_id
                # url_short_id
                # file_category
                # main_msg_id
                # company_id
                # referenceId
                # reference_type
                # uploaded_by
                # cost_id
                # is_delete
                # is_secret
                # created_at
                # has_delete
                tag_list
                # mention_user
                # secret_user
                # participants
                # star
            }
        }
        pagination {
            page
            totalPages
            total
        }
    }
}
""";

const String Get_file_galleryQuery = """
  query Get_file_gallery(\$conversation_id: String, \$conversation_ids: [String!], \$uploaded_by: String, \$file_type: String, \$file_sub_type: String, \$tag_id: [String!], \$tag_operator: String, \$file_name: String, \$from: String, \$to: String, \$page: Int, \$tab: String, \$selectedFilters: String) {
    get_file_gallery(
      conversation_id: \$conversation_id
      conversation_ids: \$conversation_ids
      uploaded_by: \$uploaded_by
      file_type: \$file_type
      file_sub_type: \$file_sub_type
      tag_id: \$tag_id
      tag_operator: \$tag_operator
      file_name: \$file_name
      from: \$from
      to: \$to
      page: \$page
      tab: \$tab
      selectedFilters: \$selectedFilters
    ) {
      tags {
        tag_id
        tagged_by
        title
        company_id
        type
        tag_color
        created_at
        updated_at
        updated_by
        team_list
        tag_type
        conversation_ids
        connected_user_ids
        user_use_count
        created_by_name
        i_connected
        my_use_count_int
        use_count
        team_list_name
        favourite
        disabled
      }
      files {
        id
        conversation_id
        conversation_title
        uploaded_by
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
        tag_list_details {
          tag_id
          tag_type
          tagged_by
          title
          tag_color
          __typename
        }
        is_delete
        is_secret
        created_at
        has_delete
        tag_list
        tag_list_with_user {
          tag_id
          created_by
          __typename
        }
        mention_user
        secret_user
        participants
        star
        __typename
      }
      pagination {
        page
        totalPages
        total
      }
      __typename
    }
}
""";

const String Get_tag_public = """
  query Tags(\$company_id: String!) {      
    tags(company_id: \$company_id) {
      public {
        tag_id
        tagged_by
        title
        company_id
        type
        tag_color
        created_at
        updated_at
        updated_by
        team_list
        tag_type
        conversation_ids
        connected_user_ids
        user_use_count
        created_by_name
        i_connected
        my_use_count_int
        use_count
        team_list_name
        favourite
        disabled
      }
    }
  }
""";

const String allLink = """
query Hub_all_link_msgs {
    hub_all_link_msgs {
        links {
            url_id
            title
            url
            msg_id
            conversation_id
            user_id
            created_at
            company_id            
            is_delete            
            conversation_title
            uploaded_by
        }
    }
}
""";

const String xmppRegisterUserQuery = """
  query xmpp_register_user(\$user_id: String, \$token: String) {
    xmpp_register_user(user_id: \$user_id, token: \$token) {
      status
      xmpp_user
      xmpp_domain
      online_user_lists
  }
}
""";

const String callHistoryGroup = """
query Call_history_group(\$user_id: String) {
  call_history_group(user_id: \$user_id) {
    status
    history_group {
      conversation_id
      sender
      call_duration
      call_status
      call_sender_ip
      call_sender_device
      call_receiver_ip
      call_receiver_device
      call_server_addr
      msg_type
      activity_id
      url_image
      img_url
      company_id
      call_running
      created_at
      conv_title
      conv_img
      short_id
    }
  }
}
""";

const String jitsiRingCallingQuery = r"""
query Jitsi_ring_calling(
  $user_id: String!,
  $conversation_id: String!,
  $company_id: String!,
  $token: String,
  $conversation_type: String,
  $participants_all: [String],
  $participants_admin: [String],
  $arr_participants: [String],
  $convname: String,
  $call_link: String,
  $call_option: String,
  $expire_unix: Float
) {
  jitsi_ring_calling(
    user_id: $user_id
    conversation_id: $conversation_id
    company_id: $company_id
    token: $token
    conversation_type: $conversation_type
    participants_all: $participants_all
    participants_admin: $participants_admin
    arr_participants: $arr_participants
    convname: $convname
    call_link: $call_link
    call_option: $call_option
    expire_unix: $expire_unix
  ) {
    status    
    jwt_token
  }
}
""";

const String filehubs_Links = """
    query Hub_all_link_msgs(\$conversation_ids: [String!], \$from: String, \$to: String, \$url: String, \$user_ids: [String!], \$sort_by: String, \$sort_style: String, \$page: Int, \$timezone: String) {
      hub_all_link_msgs(
        conversation_ids: \$conversation_ids
        from: \$from
        to: \$to
        url: \$url
        user_ids: \$user_ids
        sort_by: \$sort_by
        sort_style: \$sort_style
        page: \$page
        timezone: \$timezone
      ) {
        conversation_id_in_link
        uploaded_by_in_link
        links {
          url_id
          created_at
          msg_id
          conversation_id
          company_id
          user_id
          url
          title
          has_hide
          has_delete
          root_conv_id
          is_delete
          secret_user
          other_user
          participants
          conversation_title
          uploaded_by
        }
        pagination {
          page
          totalPages
          total
        }
      }
    }
""";

const String Categories = """
  query Categories{
      categories {
        unit_id
        unit_name
        company_id
        user_id
        created_by
        created_by_name
        total_use
        updated_at
        created_at
    }
}
""";

const String Teams = """
  query Teams {
      teams {
        team_id
        team_title
        company_id
        created_by
        updated_by
        team_system_conversation_active
        team_system_conversation_off_sms
        participants
        admin
        created_at
        updated_at
      }
  }
""";

const String All_Archive = """
  query All_archive {
      all_archive {
        status
        message
        data {
            conversation_id
            created_by
            title
            group
            team_id
            privacy
            archive
            status
            conv_img
            topic_type
            b_unit_id
            room_id
            is_busy
            company_id
            last_msg
            sender_id
            conference_id
            root_conv_id
            reset_id
            system_conversation
            system_conversation_active
            short_id
            close_for
            friend_id
            conv_is_active
            participants
            participants_name
            participants_admin
            participants_guest
            is_active
            is_pinned_users
            tag_list
            team_id_name
            b_unit_id_name
            system_conversatio_is_active
            system_conversatio_send_sms
            pin
            has_mute
            mute
            temp_user
            created_at
            last_msg_time
        }
      }
  }
""";

const String ArchiveCount = """
  query Archive_count {
      archive_count {
        status
        archive
      }
  }
""";

const String CompaniesList = """
query Companies(\$email: String!) {
  companies(email: \$email) {
    company_id
    company_name
    role
    company_img
  }
}
""";

const String Get_notifications = """
query Get_notifications(\$read_status: String!, \$page: Int) {
  get_notifications(read_status: \$read_status, page: \$page) {
    notification {
      _id
      type
      title
      body
      created_by_id
      created_by_name
      created_by_img
      receiver_id
      company_id
      task_id
      tab
      created_at
      fnln
      created_by_email      
    }
    pagination {
      page
      totalPages
      total
      __typename
    }
  }
}
""";
