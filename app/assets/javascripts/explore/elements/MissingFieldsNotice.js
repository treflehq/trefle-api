
import React, { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'

// One compact block replacing the pile of individual "unknown" rows a
// data-poor species used to show next to empty meters (see issue #238).
// Unlike the per-field "unknown" labels (Unknown.js), which anyone can edit
// straight away through their per-visitor guest token, this block is a
// deliberate call to action: it stays visible when logged out, but clicking
// it sends an anonymous visitor to sign in first rather than opening the
// correction form directly.
const MissingFieldsNotice = ({ count }) => {
  const { user, toggleEdit } = useContext(CorrectionContext)

  if (!count) return null

  const signedIn = Boolean(user && user.email)

  const handleClick = () => {
    if (signedIn) {
      toggleEdit()
    } else {
      window.location.href = window.signInPath || '/users/sign_in'
    }
  }

  return (
    <p className="missing-fields-notice" onClick={handleClick} role="button" tabIndex={0}>
      {count} field{count > 1 ? 's are' : ' is'} missing for this species — help us complete it
    </p>
  )
}

export default MissingFieldsNotice
