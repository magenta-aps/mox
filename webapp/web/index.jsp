<%--
  Created by IntelliJ IDEA.
  User: lars
  Date: 26-11-15
  Time: 10:52
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
  <head>
    <title>$Title$</title>
  </head>
  <body>
    <form action="DocumentUpload" method="POST" enctype="multipart/form-data">
      <input type="file" name="file"/><br/>
      <textarea name="authtoken"></textarea><br/>
      <input type="submit"/>
    </form>
  </body>
</html>
