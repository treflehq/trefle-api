
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import Species from './Species';
import { useEffect } from 'react';
import CorrectionContext from './CorrectionContext';
import Review from './Review';

const SpeciesPage = ({ slug }) => {
  const [submission, setSubmission] = useState({})
  const [response, setResponse] = useState({})
  const [user, setUser] = useState({})
  const [correction, setCorrection] = useState({ "average_height_value": 10 })
  const [edit, setEdit] = useState(true)
  const [review, setReview] = useState(true)

  const toggleEdit = () => {
    setEdit(!edit)
  }

  const toggleReview = () => {
    setReview(!review)
  }

  const setField = (field, value) => {
    setCorrection({...correction, [field]: value})
  }

  const setFields = (hash) => {
    setCorrection({...correction, ...hash})
  }

  const reset = () => {
    setCorrection({})
    setEdit(false)
    setReview(false)
    setSubmission({})
  }

  const submitCorrection = async (payload) => {
    const response = await fetch(
      `/api/v1/corrections/species/abies-alba?token=${temp_token}`, {
      method: 'post',
      body: JSON.stringify(payload),
      headers: { 'Content-Type': 'application/json' }
    });
    const json = await response.json();
    console.log(json);
    setSubmission(json)
    return json
  }

  useEffect(() => {
    async function fetchData() {
      const r = await axios.get(`/api/v1/species/${slug}?token=${temp_token}`)
      setResponse(r.data)
    }
    async function fetchUser() {
      const r = await axios.get(`/api/v1/me?token=${temp_token}`)
      setUser(r.data)
    }
    if (slug) {
      fetchData()
      fetchUser()
    }
  }, [])

  const correxionContext = {
    correction,
    edit,
    setField,
    setFields,
    reset,
    toggleEdit,
    user,
    review,
    toggleReview,
    setReview,
    submission,
    submitCorrection
  }

  if (response.data && user) {
    return <>
      <CorrectionContext.Provider value={correxionContext}>
        {review ? <Review species={response.data} /> : <Species species={response.data} />}
      </CorrectionContext.Provider>
    </>
  } else {
    return (<div>
      <h2>Loading...</h2>
    </div>)
  }
}

document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelectorAll("#explore-species-page").length > 0) {
    const domContainer = document.querySelector('#explore-species-page');
    const slug = document.location.pathname.split('/').slice(-1)
    ReactDOM.render(React.createElement(SpeciesPage, { slug: slug[0] }), domContainer);
  }
})

// export default SpeciesPage