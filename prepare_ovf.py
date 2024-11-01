#!/usr/bin/env python3

import argparse
import hashlib
import xml.etree.ElementTree as ET


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("image_name")
    return parser.parse_args()


def main():
    args = parse_args()

    namespaces = {
        "cim": "http://schemas.dmtf.org/wbem/wscim/1/common",
        "ovf": "http://schemas.dmtf.org/ovf/envelope/1",
        "rasd": "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData",
        "vmw": "http://www.vmware.com/schema/ovf",
        "vssd": "http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData",
        "xsi": "http://www.w3.org/2001/XMLSchema-instance",
        "": "http://schemas.dmtf.org/ovf/envelope/1",
    }

    for ns, uri in namespaces.items():
        ET.register_namespace(ns, uri)

    tree = ET.parse(f"images/{args.image_name}/{args.image_name}.ovf")
    root = tree.getroot()

    # Remove network section
    network_section = root.find("NetworkSection", namespaces)
    if network_section is not None:
        print("Removing NetworkSection...")
        root.remove(network_section)

    # Remove a network adapter from the virtual hardware section
    virtual_hardware_section = root.find(
        "VirtualSystem/VirtualHardwareSection", namespaces
    )
    if virtual_hardware_section is None:
        raise RuntimeError("Failed to find VirtualHardwareSection")

    for item in root.iter(f"{{{namespaces['']}}}Item"):
        connection_tag = item.find("rasd:Connection", namespaces)
        if connection_tag is not None and connection_tag.text == "VM Network dhcp":
            print("Removing VirtualHardware network adapter for default network...")
            virtual_hardware_section.remove(item)

    tree.write(
        f"images/{args.image_name}/{args.image_name}-efi.ovf",
        encoding="UTF-8",
        xml_declaration=True,
    )

    # Change firmware from efi to bios
    print("Creating a separate ovf with legacy bios firmware instead of efi")
    config = root.find(
        "VirtualSystem/VirtualHardwareSection/vmw:Config[@vmw:key='firmware']",
        namespaces,
    )
    if config is None:
        raise RuntimeError("Failed to find Config firmware")

    print("  Changing firmware from efi to bios..")
    config.set(f"{{{namespaces['vmw']}}}value", "bios")

    virtual_system = root.find("VirtualSystem", namespaces)
    if virtual_system is None:
        raise RuntimeError("Failed to find VirtualSystem")

    boot_order_section = root.find("VirtualSystem/vmw:BootOrderSection", namespaces)
    if boot_order_section is None:
        raise RuntimeError("Failed to find VirtualSystem/BootOrderSection")

    print("  Removing BootOrderSection...")
    virtual_system.remove(boot_order_section)

    tree.write(
        f"images/{args.image_name}/{args.image_name}-bios.ovf",
        encoding="UTF-8",
        xml_declaration=True,
    )

    # Compute the SHA1 hashes for new files
    print(ET.tostring(root, encoding="UTF-8", xml_declaration=True).decode())
    hash = hashlib.sha1()
    with open(f"{args.image_name}-efi.mf", "w") as f:
        f.write(f"SHA1({args.image_name}.ovf)= {hash.hexdigest()}")


if __name__ == "__main__":
    main()
