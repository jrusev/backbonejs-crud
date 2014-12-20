express = require("express")
bodyParser = require("body-parser")
app = express()
nohm = require("nohm").Nohm

app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use express.static("" + __dirname + "/public")

if process.env.REDISTOGO_URL
  rtg = require("url").parse(process.env.REDISTOGO_URL)
  redis = require("redis").createClient(rtg.port, rtg.hostname)
  redis.auth rtg.auth.split(":")[1]
else
  redis = require("redis").createClient()
  
nohm.setClient redis

User = nohm.model("User",
  properties:
    firstname:
      type: "string"
    lastname:
      type: "string"
    age:
      type: "integer"
)

listUsers = (req, res, next) ->
  User.find (err, ids) ->
    return next(err) if err
    users = []
    len = ids.length
    count = 0
    return res.send([]) if ids.length is 0
    ids.forEach (id) ->
      user = new User()
      user.load id, (err, props) ->
        return next(err) if err
        users.push
          id: @id
          firstname: props.firstname
          lastname: props.lastname
          age: props.age
        res.send users if ++count is len

userDetails = (req, res) ->
  User.load req.params.id, (err, properties) ->
    if err
      res.status(404).send "Not found: " + err
    else
      res.send properties

deleteUser = (req, res, next) ->
  user = new User()
  user.id = req.params.id
  user.remove (err) ->
    return next(err) if err
    res.send 204

createUser = (req, res, next) ->  
  user = nohm.factory 'User'
  user.p req.body
  user.save (err) ->
    return next(err) if err
    res.send user.allProperties(true)

updateUser = (req, res, next) ->
  user = nohm.factory 'User'  
  data =
    firstname: req.param("firstname")
    lastname: req.param("lastname")
    age: req.param("age")  
  user.p data
  user.id = req.params.id
  user.save (err) ->    
    return next(err) if err
    res.send user.allProperties(true)

app.all "*", (req, res, next) ->
  res.header "Access-Control-Allow-Origin", "*"
  res.header "Access-Control-Allow-Headers", "X-Requested-With"
  res.header "Content-Type", "application/json"
  next()


app.get "/users", listUsers
app.get "/users/:id", userDetails
app.delete "/users/:id", deleteUser
app.post "/users", createUser
app.put "/users/:id", updateUser
port = process.env.PORT or 3000
app.listen port
console.log "Server listening on port ", port