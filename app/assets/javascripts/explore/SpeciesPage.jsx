
import React, { useState } from 'react'
import ReactDOM from 'react-dom';
import axios from 'axios';
import Species from './Species';
import { useEffect } from 'react';
import CorrectionContext from './CorrectionContext';
import Review from './Review';

const SpeciesPage = ({ slug }) => {
  const [submission, setSubmission] = useState({})
  const [report, setReport] = useState({})
  const [response, setResponse] = useState({})
  const [user, setUser] = useState({})
  const [currentCorrections, setCurrentCorrections] = useState({})
  const [correction, setCorrection] = useState({})
  const [edit, setEdit] = useState(false)
  const [review, setReview] = useState(false)

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
      `/api/v1/corrections/species/${slug}?token=${temp_token}`, {
      method: 'post',
      body: JSON.stringify(payload),
      headers: { 'Content-Type': 'application/json' }
    });
    const json = await response.json();
    console.log(json);
    setSubmission(json)
    return json
  }

  const submitReport = async (payload) => {
    const response = await fetch(
      `/api/v1/species/${slug}/report?token=${temp_token}`, {
      method: 'post',
      body: JSON.stringify(payload),
      headers: { 'Content-Type': 'application/json' }
    });
    const json = await response.json();
    console.log(json);
    setReport(json)
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
    async function fetchCorrections() {
      const r = await axios.get(`/api/v1/species/${slug}/corrections?token=${temp_token}`)
      setCurrentCorrections(r.data)
    }
    if (slug) {
      fetchData()
      fetchUser()
      fetchCorrections()
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
    report,
    submitCorrection,
    submitReport,
  }

  if (response.data && user && currentCorrections) {
    return <>
      <CorrectionContext.Provider value={correxionContext}>
        {review ? <Review species={response.data} /> : <Species currentCorrections={currentCorrections && currentCorrections.data} species={response.data} />}
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