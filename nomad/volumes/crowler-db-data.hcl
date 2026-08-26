# Dynamic host volume used by the bundled PostgreSQL task.
#
# Requires Nomad >= 1.10.
# The namespace intentionally comes from NOMAD_NAMESPACE / -namespace so the
# volume, job, and Nomad Variable always use the same operator-selected scope.
#
# The built-in mkdir plugin creates a node-local persistent directory.
# Mode 0777 is intentionally portable across the PostgreSQL image's internal
# uid/gid. Production operators should tighten ownership/permissions when the
# target image uid/gid and host policy are known.

name      = "crowler-db-data"
type      = "host"
plugin_id = "mkdir"

capability {
  access_mode     = "single-node-single-writer"
  attachment_mode = "file-system"
}

parameters {
  mode = "0777"
}
