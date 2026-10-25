;(() => {
  const tabs = [...document.querySelectorAll('.g-bar [role=tab]')]
  const panels = [...document.querySelectorAll('.g-panel')]

  const show = (shot, focus) => {
    tabs.forEach((t) => {
      const on = t.dataset.shot === shot
      t.setAttribute('aria-selected', String(on))
      t.tabIndex = on ? 0 : -1
      if (on && focus) t.focus()
    })
    panels.forEach((p) => {
      p.hidden = p.id !== `p-${shot}`
    })
  }

  tabs.forEach((t) => t.addEventListener('click', () => show(t.dataset.shot)))

  document.querySelector('.g-bar')?.addEventListener('keydown', (e) => {
    const step = { ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key]
    if (!step) return
    e.preventDefault()
    const at = tabs.findIndex((t) => t.getAttribute('aria-selected') === 'true')
    show(tabs[(at + step + tabs.length) % tabs.length].dataset.shot, true)
  })

  document.querySelectorAll('[data-show]').forEach((a) => a.addEventListener('click', () => show(a.dataset.show)))

  document.querySelectorAll('.g-panel img').forEach((img) => {
    img.addEventListener('click', () => window.open(img.currentSrc || img.src, '_blank', 'noopener'))
  })
})()
