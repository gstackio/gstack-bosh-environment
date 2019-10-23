[
  {rabbit, [

    % Set the 'EXTERNAL' authentication to allow client cert auth.
    {auth_mechanisms, ['PLAIN', 'AMQPLAIN', 'EXTERNAL']},

    % Configure client cert auth to obtain the login from the Common Name (CN)
    % field of the client cert.
    {ssl_cert_login_from, common_name}
  ]}
].
