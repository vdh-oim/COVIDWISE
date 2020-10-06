const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => res.send('Hello'))
app.post('/', (req, res) => res.send('Hello'))
app.get('/noreply', (req, res) => {
})
app.post('/noreply', (req, res) => {
})

app.listen(port, "0.0.0.0", () => console.log(`Example app listening on port ${port}`))
