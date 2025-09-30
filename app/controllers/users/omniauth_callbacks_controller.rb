class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env['omniauth.auth']

    # Find or create a user based on GitHub auth data
    user = find_user_for_github_oauth(auth)

    if user.persisted?
      # If the user was found (and potentially updated), sign them in
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'GitHub') if is_navigational_format?
    elsif current_user
      # If a user is already signed in, link their GitHub account
      current_user.update(
        provider: auth.provider,
        uid: auth.uid,
        github_username: auth.info.nickname
      )
      redirect_to edit_user_registration_path, notice: 'Your GitHub account was successfully linked.'
    else
      # If the user could not be created, handle validation errors
      session['devise.github_data'] = request.env['omniauth.auth'].except(:extra)
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
  end

  def failure
    redirect_to root_path, alert: "Could not authenticate you from GitHub."
  end

  private

  def find_user_for_github_oauth(auth)
    # Find a user by provider/uid
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Find a user by email (in case they signed up manually before)
    user = User.find_by(email: auth.info.email)
    if user
      # If found by email, update their provider/uid for future sign-ins
      user.update(provider: auth.provider, uid: auth.uid, github_username: auth.info.nickname)
      return user
    end

    # If no user is found, create a new one
    User.create do |new_user|
      new_user.provider = auth.provider
      new_user.uid = auth.uid
      new_user.github_username = auth.info.nickname
      new_user.email = auth.info.email
      new_user.name = auth.info.name
      # Devise requires a password, even for OAuth.
      # We generate a random, secure one.
      new_user.password = Devise.friendly_token[0, 20]

      # Since the email is verified by GitHub, we can skip Devise's confirmation step.
      # new_user.skip_confirmation!
    end
  end

end
