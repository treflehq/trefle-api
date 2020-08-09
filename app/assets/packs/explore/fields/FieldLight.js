
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'
import { useContext } from 'react'
import CorrectionContext from '../CorrectionContext'
import ChangeInputRange from '../elements/ChangeInputRange'
import { firstNotNil } from '../utils/utils'
import MappedValue from '../elements/MappedValue'
import { invert, reverse } from 'lodash'

const FieldLight = ({
  value,
  name
}) => {
  const { edit, correction, setField } = useContext(CorrectionContext)

  const options = {
    'Dark night (< 1 lux)': 0,
    'Full moon on a clear night (10 lux)': 1,
    'Public areas with dark surroundings (50 lux)': 2,
    'Very dark overcast day (100 lux)': 3,
    'Overcast day (1000 lux)': 4,
    'Cloudy day (5 000 lux)': 5,
    'Full daylight without direct sunlight (10 000 lux)': 6,
    'Full daylight with some direct sunlight (50 000 lux)': 7,
    'Full daylight with a lot of direct sunlight (75 000 lux)': 8,
    'Direct sunlight (100 000 lux)': 9
  }

  const realValue = firstNotNil(correction[name], value)

  if (edit) {
    console.log({ realValue, reverse: invert(options) });
    return (
      <div className="columns">
        <div className="column is-12">
          <p>
            <b>Light:</b>
            {' '}
            
            <ChangeInputRange
              min={0}
              max={9}
              placeholder='Light'
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
          <b>Light:</b>
          {' '}
          <UnknownItem value={value} name={'light'} mapping={options}/>
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={realValue} leftIcon={'clouds'} rightIcon={'sun'} />
      </div>
    </div>
  )
}

export default FieldLight