
import React from 'react'
import { useContext } from 'react'
import Modal from 'react-modal'
import CorrectionContext from '../CorrectionContext'
import EditButton from '../elements/EditButton'

Modal.setAppElement('#explore-species-page')

const ReportModal = ({
  
}) => {

  const [modalIsOpen, setIsOpen] = React.useState(false);
  const [notes, setNotes] = React.useState('');
  const { edit, report, submitReport } = useContext(CorrectionContext)

  const customStyles = {
    // content: {
    //   top: '50%',
    //   left: '50%',
    //   right: 'auto',
    //   bottom: 'auto',
    //   minWidth: '60%',
    //   marginRight: '-50%',
    //   position: 'fixed',
    //   transform: 'translate(-50%, -50%)'
    // }
  };

  const openModal = () => {
    setIsOpen(true);
  }

  const afterOpenModal = () => {
  }

  const closeModal = () => {
    setIsOpen(false);
  }

  const onChange = (event) => {
    setNotes(event.target.value)
  }

  const sendReport = async () => {
    const r = await submitReport({
      notes: notes
    })

    setIsOpen(false);
  }

  console.log({ report })
  return (<>
    <div className="buttons is-pulled-right">
      <button onClick={openModal} disabled={report.data} className="button is-danger is-light is-small ">{report.data ? 'Thanks for your report' : 'Report an error'}</button>
    <EditButton />
    </div>
    <Modal
      isOpen={modalIsOpen}
      onAfterOpen={afterOpenModal}
      onRequestClose={closeModal}
      style={customStyles}
      className={`modal ${modalIsOpen ? 'is-active' : ''}`}
      contentLabel="Report an error"
    >
        <div className="modal-background"></div>
        <div className="modal-card">
          <header className="modal-card-head">
            <p className="modal-card-title">Report an error</p>
            <button className="delete" onClick={closeModal} aria-label="close"></button>
          </header>
          <section className="modal-card-body">
            <label className="label">
              Error(s) to report:
              <textarea
                className="textarea"
                placeholder="Notes"
                onChange={onChange}
                value={notes || ''}
              />
            </label>
          </section>
          <footer className="modal-card-foot">
            <button className="button is-warning" onClick={sendReport}>Report</button>
            <button onClick={closeModal} className="button">Cancel</button>
          </footer>
        </div>
    </Modal>
  </>
)
}

export default ReportModal