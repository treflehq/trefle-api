
import React from 'react'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import { keys } from 'lodash'

const EditButton = ({payload = null}) => {

  const { review, setReview, edit, user, toggleEdit, reset, submitCorrection, correction } = useContext(CorrectionContext)

  const changesCount = keys(correction).length
  const hasChanges = changesCount > 0

  if (!edit) {
    return <>
      <button className="button is-info is-light is-small is-pulled-right" onClick={toggleEdit}>Edit</button>
    </>
  } else {
    return <></>
  }
}

export default EditButton