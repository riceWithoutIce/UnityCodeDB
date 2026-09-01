# UnityCodeDB Validation Project

This tracked Unity 2022.3 project is the standard development host for focused
UnityCodeDB EditMode validation. It resolves the package from the sibling
`com.rice.ai-codedb` directory and exposes the package test assembly through
the Test Framework.

The presence of this project does not authorize starting Unity. Follow
`com.rice.ai-codedb/Documentation~/development-workflow.md` for the required
EditMode request, focused filter, time limit, and process ownership record.

Unity-generated state and test output belong under ignored directories. Product
or integration state outside those directories remains visible to Git so tests
cannot silently alter the tracked project contract.
