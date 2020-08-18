# Puzzlespace

##Permissions:

Permissions can use the wildcard * to represent a full set of permissions
at a certain level. So "*" by itself would effectively grant all permissions,
while access_saveslot:* would grant access to all saveslots

Organization Permissions | Description
--- | ---
admin:\* | Permissions related to administration of an organization. Grant with caution
admin:delete | deletes the organization
admin:rename | renames the organization
admin:create_title | permission to create titles
manage:\* | Permissions related to management of an organization
manage:grant_permission:{specified permission} | assign users specified permissions/invite new users
manage:grant_permission:\* | \* is limited to permissions a given entity already has
manage:grant_title:{title} | assign users/invite new users to specified title. \* is not valid
manage:revoke_permission:{specified permission} | allows revocation of specified permissions
manage:revoke_title:{title} | revoke title of other users
puzzle:\* | Permissions related to playing puzzles 
puzzle:access_saveslot:{slotid} | play using the specified saveslot
puzzle:create_saveslot | create new saveslots
puzzle:delete_saveslot | delete saveslots

