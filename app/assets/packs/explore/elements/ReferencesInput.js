

import React from 'react'
import CreatableSelect from 'react-select/creatable';
import { map, isNil } from 'lodash'

const ReferencesInput = ({
  className = 'references-select',
  onChange,
  value,
  placeholder,
  options,
  ...props
}) => {


  const onSelectChange = (a, b, c) => {
    console.log({ a, b, c });
    return onChange(a ? a.map(e => e.value) : null)
  }

  const isValid = (inputValue, selectValue, selectOptions) => {
    const pattern = new RegExp('^(https?:\\/\\/)?' + // protocol
      '((([a-z\\d]([a-z\\d-]*[a-z\\d])*)\\.)+[a-z]{2,}|' + // domain name
      '((\\d{1,3}\\.){3}\\d{1,3}))' + // OR ip (v4) address
      '(\\:\\d+)?(\\/[-a-z\\d%_.~+]*)*' + // port and path
      '(\\?[;&a-z\\d%_.~+=-]*)?' + // query string
      '(\\#[-a-z\\d_]*)?$', 'i'); // fragment locator
    return !!pattern.test(inputValue);
  }

  return (<span className="fieldItem edit">

    <CreatableSelect
      defaultValue={value}
      isMulti
      className={className}
      placeholder={placeholder || 'Add references...'}
      onChange={onSelectChange}
      options={[]}
      isValidNewOption={isValid}
      formatCreateLabel={(e => `Add reference ${e}`)}
      width='100%'
    />
  </span>)
}

export default ReferencesInput

