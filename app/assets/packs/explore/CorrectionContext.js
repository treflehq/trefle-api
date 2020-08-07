import React, { useState } from 'react'

const CorrectionContext = React.createContext({
  correction: {},
  edit: false,
  setField: (field, value) => { },
  toggleEdit: () => { },
})


export default CorrectionContext