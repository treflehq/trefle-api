
import React from 'react'
import Scale from '../elements/Scale'
import UnknownItem from './Unknown'

const FieldLight = ({
  value
}) => {

  if (value === null || value === undefined) {
    return <p>
      <b>Light:</b>{' '}<UnknownItem value={value} name={'light'} />
    </p>
  }

  const legend = {
    0: 'Dark night (< 1 lux)',
    1: 'Full moon on a clear night (10 lux)',
    2: 'Public areas with dark surroundings (50 lux)',
    3: 'Very dark overcast day (100 lux)',
    4: 'Overcast day (1000 lux)',
    5: 'Cloudy day (5 000 lux)',
    6: 'Full daylight without direct sunlight (10 000 lux)',
    7: 'Full daylight with some direct sunlight (50 000 lux)',
    8: 'Full daylight with a lot of direct sunlight (75 000 lux)',
    9: 'Direct sunlight (100 000 lux)'
  }

  return (
    <div className="columns">
      <div className="column is-9">
        <p>
          <b>Light:</b>
          {' '}
          {legend[value]}
        </p>
      </div>
      <div className="column is-3">
        <Scale min={0} max={9} value={value} leftIcon={'clouds'} rightIcon={'sun'} />
      </div>
    </div>
  )
}

export default FieldLight