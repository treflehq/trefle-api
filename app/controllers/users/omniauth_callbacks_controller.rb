class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    auth = request.env['omniauth.auth']

    # On cherche d'abord si un utilisateur a déjà lié ce compte GitHub
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    if user
      # Si l'utilisateur existe déjà, on le connecte
      sign_in_and_redirect user, event: :authentication
      set_flash_message(:notice, :success, kind: 'GitHub') if is_navigational_format?
    elsif current_user
      # Si un utilisateur est déjà connecté (via Devise), on LIE son compte
      current_user.update(
        provider: auth.provider,
        uid: auth.uid,
        github_username: auth.info.nickname
      )
      redirect_to edit_user_registration_path, notice: 'Your GitHub account has been linked.'
    else
      # Cas non géré : un nouvel utilisateur essaie de se connecter via GitHub
      # sans avoir de compte. Tu peux choisir de créer un compte ici ou de refuser.
      redirect_to new_user_session_path, alert: 'No account found. Please sign up first.'
    end
  end

  def failure
    redirect_to root_path
  end
end
