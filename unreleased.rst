.. Copyright (c) 2019 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
.. SPDX-License-Identifier: Apache-2.0

Release notes
#############

This page contains release notes for the SDK.

HEAD — ongoing
--------------

- [DAML Assistant] Added ``--install-assistant`` flag to ``daml install`` command,
  changing the default behavior of ``daml install`` to be "install the assistant
  whenever we are installing newer version of the SDK". Deprecated the
  ``--activate`` flag.
- [DAML Studio] Opening an already open scenario will now focus it rather than opening
  it in a new empty tab which is never updated with results.
- [DAML Studio] The selected view for scenario results (table or transaction) is now
  preserved when the scenario results are updated.
  See `#1675 <https://github.com/digital-asset/daml/issues/1675>`__.
