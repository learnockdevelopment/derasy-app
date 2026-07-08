job application
after click apply 
modal appear 
this modal must be translated
and check
en 1999
ar 1947
they must eq
check and equalize

remove add job ad
and if user has cv
show edit
if has no cv
show add your cv to apply


I/flutter (13878): 👨‍🏫 [TEACHER_SERVICE] Error applying to job: ClientException with SocketException: Connection timed out (OS Error: Connection timed out, errno = 110), address = parent.derasy.com, port = 37908, uri=https://derasy.com/api/jobs/job_123_english/apply
E/flutter (13878): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: setState() called after dispose(): _StatefulBuilderState#c4ddd(lifecycle state: defunct, not mounted)
E/flutter (13878): This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer includes the widget in its build). This error can occur when code calls setState() from a timer or an animation callback.
E/flutter (13878): The preferred solution is to cancel the timer or stop listening to the animation in the dispose() callback. Another solution is to check the "mounted" property of this object before calling setState() to ensure the object is still in the tree.
E/flutter (13878): This error might indicate a memory leak if setState() is being called because another object is retaining a reference to this State object after it has been removed from the tree. To avoid memory leaks, consider breaking the reference to this object during dispose().
E/flutter (13878): #0      State.setState.<anonymous closure> (package:flutter/src/widgets/framework.dart:1163:9)
E/flutter (13878): #1      State.setState (package:flutter/src/widgets/framework.dart:1198:6)
E/flutter (13878): #2      _TeacherJobsHubPageState._showApplyBottomSheet.<anonymous closure>.<anonymous closure> (package:derasy/views/teacher/teacher_jobs_hub_page.dart:565:44)
E/flutter (13878): <asynchronous suspension>
E/flutter (13878): 
No Overlay widget found.
Some widgets require an Overlay widget ancestor for correct operation.
The most common way to add an Overlay to an application is to include a MaterialApp, CupertinoApp or Navigator widget in the runApp() call.
The context from which that widget was searching for an overlay was:
  _Theater

  I/flutter (13878): 👨‍🏫 [TEACHER_SERVICE] POST Apply to Job: https://derasy.com/api/jobs/job_123_english/apply
D/EGL_emulation(13878): app_time_stats: avg=39.42ms min=11.60ms max=429.67ms count=23
D/EGL_emulation(13878): app_time_stats: avg=18.49ms min=11.02ms max=49.47ms count=42
I/flutter (13878): 👨‍🏫 [TEACHER_SERVICE] Apply status code: 400



print res of apply
