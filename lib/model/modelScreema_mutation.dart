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
        created_by
        updated_by
        company_img
        role
        industry
        domain_name
        plan_name
        plan_user_limit
        plan_storage_limit
        is_deactivate
        plan_id
        subscription_id
        product_id
        price_id
        class
        campus
        section
        plan_access
        created_at
        updated_at
        createdAt
        updatedAt
        team_title
        company_size
        hear_about
        phone_number
        company_email
        company_address
        company_website
        business_type
        registration_number
        tin_number
        social_link
        module
        created_by_role
        company_contact_person
        same_address
    }
  }
}
""";
