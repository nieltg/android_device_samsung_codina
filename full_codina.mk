# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, device/samsung/codina/codina.mk)

# Discard inherited values and use our own instead.
PRODUCT_NAME := full_codina
PRODUCT_DEVICE := codina
PRODUCT_BRAND := samsung
PRODUCT_MANUFACTURER := samsung
PRODUCT_MODEL := GT-I8160
