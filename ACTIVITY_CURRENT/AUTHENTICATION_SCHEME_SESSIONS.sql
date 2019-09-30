SELECT
	c.session_id
	, s.login_name
	, c.client_net_address
	, s.host_name
	, c.local_tcp_port
	, c.auth_scheme

FROM sys.dm_exec_connections AS c
INNER JOIN sys.dm_exec_sessions s ON s.session_id = c.session_id
--WHERE c.auth_scheme IN ('KERBEROS', 'NTLM') -- c.client_net_address = '10.135.131.194' --

SELECT 
	c.auth_scheme AS [AuthenticationScheme]
	,COUNT(c.auth_scheme) AS [SessionCount]
FROM sys.dm_exec_connections AS c
INNER JOIN sys.dm_exec_sessions s ON s.session_id = c.session_id
GROUP BY c.auth_scheme