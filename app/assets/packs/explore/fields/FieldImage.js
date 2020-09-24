
import React from 'react'
import UnknownItem from './Unknown'
import CorrectionContext from '../CorrectionContext'
import { useContext } from 'react'
import { firstNotNil } from '../utils/utils'
import ReactIntense from 'react-intense'

const FieldImage = ({
  image
}) => {
  // const { edit, correction, setFields } = useContext(CorrectionContext)
  // const realValue = firstNotNil(correction[name], value)

  // const onChange = (v) => {
  //   setFields({
  //     [`${name}`]: v.target.value,
  //   })
  // }

  // if (edit) {
  //   return (<label className="label">
  //     Observations:
  //     <textarea
  //     className="textarea"
  //     placeholder="Observations"
  //     onChange={onChange}
  //     value={realValue || ''}
  //   />
  //   </label>)
  // }

  return <span>
    <ReactIntense src={image.image_url} vertical={false} moveSpeed={0} caption={image.copyright} />
  </span>
}

export default FieldImage