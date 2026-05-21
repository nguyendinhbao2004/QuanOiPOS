triển khai feature login 

flow đăng ký sẽ có 2 step user sẽ đăng ký với thông tin
'/auth/register'
'
{
  "email": "string",
  "password": "string",
  "fullName": "string"
}
'
sau khi đăng ký thì user sẽ qua bước xác nhận otp

'/auth/register/confirm'

{
  "email": "string",
  "otpCode": "string"
}


áp dung partern UI/UX 