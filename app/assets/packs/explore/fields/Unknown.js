
import React from 'react'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'

const UnknownItem = ({ value, name }) => {

  const { toggleEdit } = useContext(CorrectionContext)

  return (<span key={name} onClick={toggleEdit} className="unknownItem">
    unknown
  </span>)
}

export default UnknownItem