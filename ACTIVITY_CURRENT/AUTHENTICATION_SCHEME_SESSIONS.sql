DECLARE @MachineName NVARCHAR(256)

SELECT @MachineName = CAST(SERVERPROPERTY('MachineName') AS NVARCHAR(256))
--SELECT @MachineName

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
WHERE 
            s.host_name <> @MachineName --  we do not care about the locally logged in sessions
AND         s.host_name NOT LIKE 'WH%'

SELECT 
	c.auth_scheme AS [AuthenticationScheme]
	,COUNT(c.auth_scheme) AS [SessionCount]
FROM sys.dm_exec_connections AS c
INNER JOIN sys.dm_exec_sessions s ON s.session_id = c.session_id
WHERE 
            s.host_name <> @MachineName --  we do not care about the locally logged in sessions
AND         s.host_name NOT LIKE 'WH%'
GROUP BY c.auth_scheme
