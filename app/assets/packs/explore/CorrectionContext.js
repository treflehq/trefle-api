import React, { useState } from 'react'

const CorrectionContext = React.createContext({
  correction: {},
  user: {},
  edit: false,
  setField: (field, value) => { },
  toggleEdit: () => { },
  reset: () => { },
})


export default CorrectionContext