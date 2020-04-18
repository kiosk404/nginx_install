;
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	demo.com. demo.com. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	127.0.0.1.
@	IN	A	127.0.0.1
@	IN	AAAA	::1
