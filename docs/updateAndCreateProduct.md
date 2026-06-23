FE cần tích hợp upload ảnh sản phẩm theo luồng mới sau:
Xin quyền upload từ BE:
POST /api/products/image-upload-url
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "storeId": 1,
  "contentType": "image/webp"
}
contentType chỉ hỗ trợ:
image/jpeg
image/png
image/webp
Response mẫu:
{
  "succeeded": true,
  "message": "Đã tạo URL tải ảnh lên.",
  "data": {
    "key": "products/1/2af7....webp",
    "imageUrl": "https://cdn.quanoi.vn/products/1/2af7....webp",
    "uploadUrl": "https://quanoi-product-images-prod.s3....X-Amz-Signature=...",
    "expiresAt": "2026-06-22T..."
  }
}
Upload file thẳng lên S3 bằng uploadUrl. Không gửi Authorization header cho request này; chỉ gửi đúng Content-Type đã dùng khi xin URL.
async function uploadProductImage(file: File, storeId: number) {
  const urlResponse = await api.post("/api/products/image-upload-url", {
    storeId,
    contentType: file.type,
  });

  const { uploadUrl, imageUrl, key } = urlResponse.data.data;

  const uploadResponse = await fetch(uploadUrl, {
    method: "PUT",
    headers: {
      "Content-Type": file.type,
    },
    body: file,
  });

  if (!uploadResponse.ok) {
    throw new Error("Không thể tải ảnh lên.");
  }

  return { imageUrl, key };
}
Sau khi upload thành công, dùng imageUrl để tạo/cập nhật sản phẩm:
const { imageUrl } = await uploadProductImage(selectedFile, form.storeId);

await api.post("/api/products", {
  storeId: form.storeId,
  categoryId: form.categoryId,
  name: form.name,
  imageUrl,
  description: form.description,
  preparationTime: form.preparationTime,
  price: form.price,
  costPrice: form.costPrice,
  type: form.type,
  variants: form.variants,
  toppingIds: form.toppingIds,
  recipes: form.recipes,
});
Lưu ý:
uploadUrl là URL bí mật, chỉ dùng để PUT file và hết hạn sau 5 phút. Không lưu nó vào database, không hiển thị, không log ra console production.
Lưu imageUrl vào trường ImageUrl của sản phẩm.
Gọi lại API xin URL mới nếu upload hết hạn hoặc lỗi.
Không dùng AWS access key/secret key ở frontend.
Header Content-Type lúc PUT phải giống lúc gọi API xin URL; ví dụ xin image/webp thì upload cũng phải là image/webp.