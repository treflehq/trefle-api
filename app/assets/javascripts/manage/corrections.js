// Review queue: "select the page" checkbox, the selected count, and the
// scroll position kept across a decision (the page reloads after each one).
const SCROLL_KEY = 'corrections-review-scroll'

export default function corrections() {
  const form = document.getElementById('corrections-form')
  if (!form) return

  try {
    const saved = sessionStorage.getItem(SCROLL_KEY)
    sessionStorage.removeItem(SCROLL_KEY)
    if (saved) window.scrollTo(0, parseInt(saved, 10))
  } catch (e) { /* storage unavailable: start at the top */ }
  form.addEventListener('submit', () => {
    try { sessionStorage.setItem(SCROLL_KEY, String(window.scrollY)) } catch (e) { /* ignore */ }
  })

  document.querySelectorAll('.corrections-review__toast').forEach((toast) => {
    toast.addEventListener('click', () => toast.remove())
    setTimeout(() => toast.remove(), 8000)
  })

  const all = form.querySelector('[data-corrections-select-all]')
  const count = form.querySelector('[data-corrections-selected-count]')
  const boxes = () => Array.from(form.querySelectorAll('[data-corrections-select]'))
  const refresh = () => {
    const selected = boxes().filter((box) => box.checked).length
    count.textContent = selected ? `${selected} selected` : ''
    all.checked = selected > 0 && selected === boxes().length
  }

  form.querySelector('[data-corrections-select-noop]')?.addEventListener('click', () => {
    boxes().forEach((box) => { box.checked = box.hasAttribute('data-corrections-noop') })
    refresh()
  })

  all.addEventListener('change', () => {
    boxes().forEach((box) => { box.checked = all.checked })
    refresh()
  })
  boxes().forEach((box) => box.addEventListener('change', refresh))
  refresh()

  // Enter in a comment field would submit the bulk form with no decision.
  form.querySelectorAll('[data-corrections-comment]').forEach((input) => {
    input.addEventListener('keydown', (event) => { if (event.key === 'Enter') event.preventDefault() })
  })
}
