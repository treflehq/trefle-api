
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import MappedValue from '../elements/MappedValue'
import { invert, reverse } from 'lodash'


const FieldAtmosphericHumidity = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)
  const realValue = firstNotNil(correction[name], value)

  const options = {
    'Less than 10%': 0,
    '10%': 1,
    '20%': 2,
    '30%': 3,
    '40%': 4,
    '50%': 5,
    '60%': 6,
    '70%': 7,
    '80%': 8,
    '> 90%': 9
  }

  if (edit) {
    console.log({ realValue, reverse: invert(options) });
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Atmospheric Humidity:</b>
            {' '}

            <ChangeInputRange
              min={0}
              max={9}
              onChange={(e) => setField(name, parseInt(e.target.value))}
              value={realValue}
            />

            <span>
              {' '}
              {invert(options)[realValue]}
            </span>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Atmospheric Humidity:</b>
          {' '}
          <UnknownItem value={value} name={name} mapping={options} />
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={realValue} leftIcon={'tint'} />
      </div>
    </div>
  )
}

export default FieldAtmosphericHumidity