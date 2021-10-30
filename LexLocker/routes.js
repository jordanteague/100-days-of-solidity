const routes = require("next-routes")();

routes
  .add("/lockers/new", "/lockers/new")
  .add("/lockers/:uint256", "/lockers/manage")
  .add("/", "/")

module.exports = routes;
