# Configure Mission Control Jobs authentication.
# Use our AdminController as the base class (which requires admin login).
# Disable the built-in HTTP Basic authentication since we handle auth ourselves.
MissionControl::Jobs.base_controller_class = "AdminController"
MissionControl::Jobs.http_basic_auth_enabled = false
