import React, { useState } from 'react'

const CorrectionContext = React.createContext({
  correction: {},
  submission: {},
  user: {},
  edit: false,
  setField: (field, value) => { },
  setFields: (hash) => { },
  toggleEdit: () => { },
  reset: () => { },
  review: false,
  toggleReview: () => { },
  setReview: (value) => { },
  submitCorrection: async (payload) => { },
})


export default CorrectionContext