testing_task_runner:
  file.managed:
    - name: /tmp/testfile
    - source: salt://files/testfile.j2
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - context:
        some_var: This should be the output